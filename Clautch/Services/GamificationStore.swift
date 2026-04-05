import Foundation
import os

/// Tracks streaks and achievements. Follows the same singleton pattern as SessionStats.
@Observable
@MainActor
final class GamificationStore {
    static let shared = GamificationStore()

    private static let streakKey = "com.clautch.streakData"
    private static let achievementsKey = "com.clautch.achievements"
    private static let countersKey = "com.clautch.achievementCounters"
    private static let xpKey = "com.clautch.xp"

    private let logger = Logger(subsystem: "com.clautch.app", category: "Gamification")

    private(set) var streak: StreakData
    private(set) var earnedAchievements: [EarnedAchievement]
    private(set) var counters: AchievementCounters
    private(set) var xp: Int

    /// Current evolution stage, derived from XP.
    var evolution: CreatureEvolution { CreatureEvolution.from(xp: xp) }

    /// Queue of achievements waiting to be celebrated. Views pop from the front.
    var celebrationQueue: [AchievementId] = []

    struct AchievementCounters: Codable {
        var totalSessions: Int = 0
        var totalToolUses: Int = 0
        var totalReactionsSent: Int = 0
        var hasJoinedRoom: Bool = false
        var hadSpeedBurst: Bool = false
    }

    private init() {
        streak = Self.loadJSON(key: Self.streakKey) ?? StreakData()
        earnedAchievements = Self.loadJSON(key: Self.achievementsKey) ?? []
        counters = Self.loadJSON(key: Self.countersKey) ?? AchievementCounters()
        xp = UserDefaults.standard.integer(forKey: Self.xpKey)
        checkAndUpdateStreak()
    }

    /// Test-only initializer with injected state.
    init(streak: StreakData, achievements: [EarnedAchievement], counters: AchievementCounters, xp: Int = 0) {
        self.streak = streak
        self.earnedAchievements = achievements
        self.counters = counters
        self.xp = xp
    }

    // MARK: - Event Recording

    func recordSessionStart() {
        counters.totalSessions += 1
        addXP(5) // +5 XP per session
        checkAndUpdateStreak()

        // Early bird: session started before 6 AM
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 6 {
            unlockIfNew(.earlyBird)
        }

        saveCounters()
        checkAchievements()
    }

    func recordSessionEnd(duration: TimeInterval, startHour: Int) {
        // Marathon: 4+ hour session
        if duration >= 4 * 3600 {
            unlockIfNew(.marathon)
        }

        // Night owl: session that ran past midnight (started before midnight, ended after)
        let endHour = Calendar.current.component(.hour, from: Date())
        if endHour >= 0 && endHour < 5 {
            unlockIfNew(.nightOwl)
        }

        checkAchievements()
    }

    func recordToolUse() {
        counters.totalToolUses += 1
        addXP(1) // +1 XP per tool use
        saveCounters()
        checkAchievements()
    }

    func recordSpeedBurst() {
        counters.hadSpeedBurst = true
        saveCounters()
        unlockIfNew(.speedDemon)
    }

    func recordRoomJoined() {
        counters.hasJoinedRoom = true
        saveCounters()
        checkAchievements()
    }

    func recordReactionSent() {
        counters.totalReactionsSent += 1
        saveCounters()
        checkAchievements()
    }

    // MARK: - XP

    private func addXP(_ amount: Int) {
        let oldStage = evolution
        xp += amount
        saveXP()
        let newStage = evolution
        if newStage != oldStage {
            ActivityFeed.shared.add(icon: "⬆", text: "Evolved to \(newStage.displayName)!")
            NotificationService.shared.playSound(.reactionReceived)
            logger.info("Evolution: \(oldStage.displayName) → \(newStage.displayName)")
        }
    }

    // MARK: - Streak

    func checkAndUpdateStreak() {
        let today = SessionStats.dateKey(for: Date())

        // Already counted today
        if streak.lastActiveDate == today { return }

        let calendar = Calendar.current
        if let lastDate = streak.lastActiveDate,
           let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()),
           lastDate == SessionStats.dateKey(for: yesterday) {
            // Consecutive day
            streak.currentStreak += 1
            addXP(3) // +3 XP per streak day
        } else {
            // Streak broken or first day
            if streak.currentStreak > 0 {
                ActivityFeed.shared.add(icon: "🔥", text: "Streak ended at \(streak.currentStreak)d")
            }
            streak.currentStreak = 1
            streak.streakStartDate = today
        }

        streak.lastActiveDate = today
        streak.longestStreak = max(streak.longestStreak, streak.currentStreak)
        saveStreak()
        checkAchievements()
    }

    // MARK: - Achievement Checking

    func isEarned(_ id: AchievementId) -> Bool {
        earnedAchievements.contains { $0.achievementId == id }
    }

    var unearnedCount: Int {
        AchievementId.allCases.count - earnedAchievements.count
    }

    private func checkAchievements() {
        for id in AchievementId.allCases {
            guard !isEarned(id) else { continue }
            let earned: Bool
            switch id {
            case .firstSession:     earned = counters.totalSessions >= 1
            case .tenSessions:      earned = counters.totalSessions >= 10
            case .fiftySessions:    earned = counters.totalSessions >= 50
            case .bugSquasher:      earned = counters.totalToolUses >= 100
            case .speedDemon:       earned = counters.hadSpeedBurst
            case .teamPlayer:       earned = counters.hasJoinedRoom
            case .socialButterfly:  earned = counters.totalReactionsSent >= 10
            case .streakThree:      earned = streak.currentStreak >= 3
            case .streakSeven:      earned = streak.currentStreak >= 7
            case .streakThirty:     earned = streak.currentStreak >= 30
            // These are checked explicitly in their record* methods
            case .marathon, .nightOwl, .earlyBird:
                earned = false
            }
            if earned { unlock(id) }
        }
    }

    private func unlockIfNew(_ id: AchievementId) {
        guard !isEarned(id) else { return }
        unlock(id)
    }

    private func unlock(_ id: AchievementId) {
        let record = EarnedAchievement(achievementId: id, earnedAt: Date())
        earnedAchievements.append(record)
        celebrationQueue.append(id)
        addXP(20) // +20 XP per achievement
        saveAchievements()

        ActivityFeed.shared.add(icon: "⭐", text: "Achievement: \(id.title)")
        NotificationService.shared.playSound(.reactionReceived)
        logger.info("Achievement unlocked: \(id.rawValue)")
    }

    /// Pop the next achievement to celebrate. Called by the floater animation.
    func popCelebration() -> AchievementId? {
        guard !celebrationQueue.isEmpty else { return nil }
        return celebrationQueue.removeFirst()
    }

    // MARK: - Accessory Unlocks

    /// Returns the set of accessories the player has unlocked based on current progress.
    var unlockedAccessories: Set<CreatureAccessory> {
        Set(CreatureAccessory.allCases.filter { isAccessoryUnlocked($0) })
    }

    func isAccessoryUnlocked(_ accessory: CreatureAccessory) -> Bool {
        switch accessory.unlockRequirement {
        case .free:
            return true
        case .achievement(let id):
            return isEarned(id)
        case .streak(let days):
            return streak.longestStreak >= days
        case .xp(let amount):
            return xp >= amount
        }
    }

    // MARK: - Persistence

    private func saveStreak() {
        Self.saveJSON(streak, key: Self.streakKey)
    }

    private func saveAchievements() {
        Self.saveJSON(earnedAchievements, key: Self.achievementsKey)
    }

    private func saveCounters() {
        Self.saveJSON(counters, key: Self.countersKey)
    }

    private func saveXP() {
        UserDefaults.standard.set(xp, forKey: Self.xpKey)
    }

    private static func loadJSON<T: Decodable>(key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func saveJSON<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
