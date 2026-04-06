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
        var hasRecoveredFromErrors: Bool = false
        var longestPositiveMoodRun: Int = 0
        var totalCodingSeconds: TimeInterval = 0
    }

    private init() {
        streak = Self.loadJSON(key: Self.streakKey) ?? StreakData()
        earnedAchievements = Self.loadJSON(key: Self.achievementsKey) ?? []
        counters = Self.loadJSON(key: Self.countersKey) ?? AchievementCounters()
        xp = UserDefaults.standard.integer(forKey: Self.xpKey)
        checkAndUpdateStreak()
        loadQuests()
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
        updateQuestProgress()
    }

    func recordSessionEnd(duration: TimeInterval, startHour: Int) {
        // Session length bonus: +1 XP per 10 minutes, capped at +12
        let lengthBonus = min(Int(duration / 600), 12)
        if lengthBonus > 0 {
            addXP(lengthBonus)
        }

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
        updateQuestProgress()
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

    /// Bonus XP when recovering from 3+ consecutive errors.
    func recordErrorRecovery() {
        addXP(3)
        counters.hasRecoveredFromErrors = true
        saveCounters()
        checkAchievements()
    }

    /// Bonus XP for sustained tool velocity (5+ tools in 30s).
    func recordToolVelocityBonus() {
        addXP(2)
    }

    /// Record coding time for time-based achievements.
    func recordCodingTime(_ seconds: TimeInterval) {
        counters.totalCodingSeconds += seconds
        saveCounters()
        checkAchievements()
    }

    /// Track positive mood runs for Zen Master achievement.
    func recordMoodSample(_ emotion: String) {
        let isPositive = emotion == "happy" || emotion == "excited" || emotion == "neutral"
        if isPositive {
            counters.longestPositiveMoodRun += 1
        } else {
            counters.longestPositiveMoodRun = 0
        }
        saveCounters()
        checkAchievements()
    }

    // MARK: - XP

    private func addXP(_ amount: Int) {
        let oldStage = evolution
        // Streak multiplier: 1.0 at 0 days, +5% per streak day, capped at 2.0×
        let multiplier = min(2.0, 1.0 + Double(streak.currentStreak) * 0.05)
        let effectiveAmount = max(1, Int(ceil(Double(amount) * multiplier)))
        xp += effectiveAmount
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
            // Session milestones
            case .firstSession:         earned = counters.totalSessions >= 1
            case .fiveSessions:         earned = counters.totalSessions >= 5
            case .tenSessions:          earned = counters.totalSessions >= 10
            case .twentyFiveSessions:   earned = counters.totalSessions >= 25
            case .fiftySessions:        earned = counters.totalSessions >= 50
            case .hundredSessions:      earned = counters.totalSessions >= 100
            // Tool milestones
            case .bugSquasher:          earned = counters.totalToolUses >= 100
            case .toolsmith:            earned = counters.totalToolUses >= 250
            case .prolific:             earned = counters.totalToolUses >= 500
            case .speedDemon:           earned = counters.hadSpeedBurst
            // Coding time
            case .centurion:            earned = counters.totalCodingSeconds >= 3600
            case .dedicated:            earned = counters.totalCodingSeconds >= 36000
            case .ironclad:             earned = counters.totalCodingSeconds >= 180000
            // Resilience & mood
            case .resilient:            earned = counters.hasRecoveredFromErrors
            case .zenMaster:            earned = counters.longestPositiveMoodRun >= 20
            // Social
            case .teamPlayer:           earned = counters.hasJoinedRoom
            case .socialButterfly:      earned = counters.totalReactionsSent >= 10
            // Streaks
            case .streakThree:          earned = streak.currentStreak >= 3
            case .streakSeven:          earned = streak.currentStreak >= 7
            case .streakFourteen:       earned = streak.currentStreak >= 14
            case .streakThirty:         earned = streak.currentStreak >= 30
            // Checked explicitly in their record* methods
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

    // MARK: - Daily Quests

    struct DailyQuest: Codable, Identifiable {
        let id: String
        let title: String
        let target: Int
        var progress: Int = 0
        var completed: Bool = false
    }

    private static let questsKey = "com.clautch.dailyQuests"
    private static let questDateKey = "com.clautch.questDate"
    private(set) var dailyQuests: [DailyQuest] = []
    private var questDate: String = ""

    var completedQuestCount: Int {
        dailyQuests.filter(\.completed).count
    }

    private func loadQuests() {
        questDate = UserDefaults.standard.string(forKey: Self.questDateKey) ?? ""
        dailyQuests = Self.loadJSON(key: Self.questsKey) ?? []
        refreshQuestsIfNeeded()
    }

    private func refreshQuestsIfNeeded() {
        let today = SessionStats.dateKey(for: Date())
        guard questDate != today else { return }

        // Generate 3 quests from pool, seeded by date
        let pool: [(id: String, title: String, target: Int)] = [
            ("tools15",   "Use 15 tools today",            15),
            ("time30",    "Code for 30 minutes",           30),
            ("morning",   "Start a session before 9 AM",    1),
            ("mood10",    "10 positive mood samples",       10),
            ("tools25",   "Use 25 tools today",            25),
            ("time60",    "Code for 1 hour",               60),
            ("sessions2", "Complete 2 sessions",             2),
            ("reaction",  "Send a reaction in a room",       1),
        ]

        var seed = today.hashValue
        var indices: Set<Int> = []
        while indices.count < 3 {
            seed = seed &* 6364136223846793005 &+ 1
            let idx = abs(seed) % pool.count
            indices.insert(idx)
        }

        dailyQuests = indices.sorted().map { idx in
            let q = pool[idx]
            return DailyQuest(id: q.id, title: q.title, target: q.target)
        }
        questDate = today
        saveQuests()
    }

    /// Update quest progress after any gamification event.
    func updateQuestProgress() {
        refreshQuestsIfNeeded()
        let today = SessionStats.dateKey(for: Date())
        let todaySeconds = SessionStats.shared.dailyTotals[today] ?? 0
        let todayMinutes = Int(todaySeconds / 60)

        for i in dailyQuests.indices {
            guard !dailyQuests[i].completed else { continue }
            let oldProgress = dailyQuests[i].progress
            switch dailyQuests[i].id {
            case "tools15":   dailyQuests[i].progress = min(counters.totalToolUses, 15) // approximate with daily
            case "tools25":   dailyQuests[i].progress = min(counters.totalToolUses, 25)
            case "time30":    dailyQuests[i].progress = min(todayMinutes, 30)
            case "time60":    dailyQuests[i].progress = min(todayMinutes, 60)
            case "mood10":    dailyQuests[i].progress = min(counters.longestPositiveMoodRun, 10)
            case "sessions2": dailyQuests[i].progress = min(counters.totalSessions, 2)
            case "morning":   dailyQuests[i].progress = Calendar.current.component(.hour, from: Date()) < 9 && counters.totalSessions > 0 ? 1 : dailyQuests[i].progress
            case "reaction":  dailyQuests[i].progress = min(counters.totalReactionsSent, 1)
            default: break
            }

            if dailyQuests[i].progress >= dailyQuests[i].target && oldProgress < dailyQuests[i].target {
                dailyQuests[i].completed = true
                addXP(5)
                ActivityFeed.shared.add(icon: "✅", text: "Quest complete: \(dailyQuests[i].title)")
            }
        }
        saveQuests()
    }

    private func saveQuests() {
        Self.saveJSON(dailyQuests, key: Self.questsKey)
        UserDefaults.standard.set(questDate, forKey: Self.questDateKey)
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
