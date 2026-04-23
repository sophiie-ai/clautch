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
    private static let prestigeKey = "com.clautch.prestige"
    private static let dailyCountersKey = "com.clautch.dailyCounters"
    private static let resetVersionKey = "com.clautch.resetVersion"

    /// Bump this when gamification state must be wiped for everyone (e.g. to
    /// nullify scores from a period where tampering was observed). Each client
    /// wipes exactly once when it first sees a version higher than the one stored.
    private static let currentResetVersion = 1

    private let logger = Logger(subsystem: "com.clautch.app", category: "Gamification")

    private(set) var streak: StreakData
    private(set) var earnedAchievements: [EarnedAchievement]
    private(set) var counters: AchievementCounters
    private(set) var dailyCounters: DailyCounters
    private(set) var xp: Int
    private(set) var prestige: PrestigeData

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
        var totalStatusSets: Int = 0

        // Personality counters
        var nightSessionCount: Int = 0
        var errorRecoveryCount: Int = 0
        var speedBurstCount: Int = 0
        var uniqueToolNames: [String] = []
    }

    /// Counters scoped to the current day, used for daily quest progress.
    struct DailyCounters: Codable {
        var date: String = ""  // "yyyy-MM-dd"
        var toolUses: Int = 0
        var sessions: Int = 0
        var reactionsSent: Int = 0
        var positiveMoodRun: Int = 0
        var feedCount: Int = 0
        var petCount: Int = 0
        var pokeCount: Int = 0
    }

    private init() {
        Self.applyGlobalResetIfNeeded()
        streak = Self.loadJSON(key: Self.streakKey) ?? StreakData()
        earnedAchievements = Self.loadJSON(key: Self.achievementsKey) ?? []
        counters = Self.loadJSON(key: Self.countersKey) ?? AchievementCounters()
        dailyCounters = Self.loadJSON(key: Self.dailyCountersKey) ?? DailyCounters()
        xp = UserDefaults.standard.integer(forKey: Self.xpKey)
        prestige = Self.loadJSON(key: Self.prestigeKey) ?? PrestigeData()
        resetDailyCountersIfNeeded()
        checkAndUpdateStreak()
        loadQuests()
        loadWeeklyChallenges()
    }

    /// Wipe every gamification UserDefaults key when the stored reset version is
    /// behind `currentResetVersion`. Runs before any load so the fresh defaults
    /// are what the rest of init sees.
    private static func applyGlobalResetIfNeeded() {
        let defaults = UserDefaults.standard
        let stored = defaults.integer(forKey: resetVersionKey)
        guard stored < currentResetVersion else { return }
        let keys = [
            streakKey, achievementsKey, countersKey, xpKey, prestigeKey,
            dailyCountersKey, questsKey, questDateKey,
            weeklyChallengesKey, weeklyDateKey,
        ]
        for key in keys { defaults.removeObject(forKey: key) }
        defaults.set(currentResetVersion, forKey: resetVersionKey)
    }

    /// Test-only initializer with injected state.
    init(streak: StreakData, achievements: [EarnedAchievement], counters: AchievementCounters, xp: Int = 0, prestige: PrestigeData = PrestigeData()) {
        self.streak = streak
        self.earnedAchievements = achievements
        self.counters = counters
        self.dailyCounters = DailyCounters(date: SessionStats.dateKey(for: Date()))
        self.xp = xp
        self.prestige = prestige
    }

    // MARK: - Daily Counter Reset

    private func resetDailyCountersIfNeeded() {
        let today = SessionStats.dateKey(for: Date())
        guard dailyCounters.date != today else { return }
        dailyCounters = DailyCounters(date: today)
        saveDailyCounters()
    }

    private func saveDailyCounters() {
        Self.saveJSON(dailyCounters, key: Self.dailyCountersKey)
    }

    // MARK: - Event Recording

    func recordSessionStart() {
        resetDailyCountersIfNeeded()
        counters.totalSessions += 1
        dailyCounters.sessions += 1
        addXP(5) // +5 XP per session
        checkAndUpdateStreak()

        // Early bird: session started before 6 AM
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 6 {
            unlockIfNew(.earlyBird)
        }

        saveCounters()
        saveDailyCounters()
        checkAchievements()
        updateQuestProgress()
        updateWeeklyChallengeProgress()
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

        // Track night sessions for personality
        if startHour >= 22 || startHour < 5 {
            counters.nightSessionCount += 1
            saveCounters()
        }

        checkAchievements()

        // Recalculate personality traits at session boundary
        PersonalityEngine.shared.recalculate()
    }

    /// Record a local creature interaction (pet/poke/feed).
    func recordInteraction(_ type: StateMachine.LocalInteraction) {
        resetDailyCountersIfNeeded()
        switch type {
        case .pet:
            dailyCounters.petCount += 1
        case .poke:
            dailyCounters.pokeCount += 1
        case .feed:
            guard dailyCounters.feedCount < 3 else {
                saveDailyCounters()
                return
            }
            dailyCounters.feedCount += 1
            addXP(1)
        }
        saveDailyCounters()
    }

    /// Record a tool name for personality trait tracking (tool variety).
    func recordToolName(_ name: String) {
        guard !counters.uniqueToolNames.contains(name) else { return }
        counters.uniqueToolNames.append(name)
        // Cap at 100 to bound storage
        if counters.uniqueToolNames.count > 100 {
            counters.uniqueToolNames.removeFirst()
        }
        saveCounters()
    }

    func recordToolUse() {
        resetDailyCountersIfNeeded()
        counters.totalToolUses += 1
        dailyCounters.toolUses += 1
        addXP(1) // +1 XP per tool use
        saveCounters()
        saveDailyCounters()
        checkAchievements()
        updateQuestProgress()
        updateWeeklyChallengeProgress()
    }

    func recordSpeedBurst() {
        counters.hadSpeedBurst = true
        counters.speedBurstCount += 1
        saveCounters()
        unlockIfNew(.speedDemon)
    }

    func recordRoomJoined() {
        counters.hasJoinedRoom = true
        saveCounters()
        checkAchievements()
    }

    func recordReactionSent() {
        resetDailyCountersIfNeeded()
        counters.totalReactionsSent += 1
        dailyCounters.reactionsSent += 1
        saveCounters()
        saveDailyCounters()
        checkAchievements()
    }

    /// Bonus XP when recovering from 3+ consecutive errors.
    func recordErrorRecovery() {
        addXP(3)
        counters.hasRecoveredFromErrors = true
        counters.errorRecoveryCount += 1
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
        resetDailyCountersIfNeeded()
        let isPositive = emotion == "happy" || emotion == "excited" || emotion == "neutral"
        if isPositive {
            counters.longestPositiveMoodRun += 1
            dailyCounters.positiveMoodRun += 1
        } else {
            counters.longestPositiveMoodRun = 0
            dailyCounters.positiveMoodRun = 0
        }
        saveCounters()
        saveDailyCounters()
        checkAchievements()
    }

    func recordStatusSet() {
        counters.totalStatusSets += 1
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
            JournalStore.shared.record(type: .evolution, title: "Evolved to \(newStage.displayName)", detail: "Reached \(xp) XP", evolution: newStage)
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
            // Status
            case .statusSetter:         earned = counters.totalStatusSets >= 25
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
        JournalStore.shared.record(type: .achievement, title: "Achievement: \(id.title)", detail: id.description, evolution: CreatureEvolution.from(xp: xp))
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
        case .prestige(let level):
            return prestige.level >= level
        }
    }

    // MARK: - Prestige / Rebirth

    /// Whether the player can prestige (must be at Ancient stage).
    var canPrestige: Bool { evolution == .ancient }

    /// Rebirth: reset XP to 0, increment prestige level, keep achievements & streaks.
    func performPrestige() {
        guard canPrestige else { return }
        prestige.lifetimeXP += xp
        prestige.level += 1
        xp = 0
        saveXP()
        savePrestige()

        ActivityFeed.shared.add(icon: "🌟", text: "Prestige \(prestige.level)! Reborn as Baby")
        NotificationService.shared.playSound(.reactionReceived)
        JournalStore.shared.record(type: .prestige, title: "Prestige \(prestige.level)!", detail: "Reborn with \(prestige.lifetimeXP) lifetime XP")
        logger.info("Prestige rebirth to level \(self.prestige.level), lifetime XP: \(self.prestige.lifetimeXP)")
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
            case "tools15":   dailyQuests[i].progress = min(dailyCounters.toolUses, 15)
            case "tools25":   dailyQuests[i].progress = min(dailyCounters.toolUses, 25)
            case "time30":    dailyQuests[i].progress = min(todayMinutes, 30)
            case "time60":    dailyQuests[i].progress = min(todayMinutes, 60)
            case "mood10":    dailyQuests[i].progress = min(dailyCounters.positiveMoodRun, 10)
            case "sessions2": dailyQuests[i].progress = min(dailyCounters.sessions, 2)
            case "morning":   dailyQuests[i].progress = dailyCounters.sessions > 0 && Calendar.current.component(.hour, from: Date()) < 9 ? 1 : dailyQuests[i].progress
            case "reaction":  dailyQuests[i].progress = min(dailyCounters.reactionsSent, 1)
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

    // MARK: - Weekly Challenges

    struct WeeklyChallenge: Codable, Identifiable {
        let id: String
        let title: String
        let target: Int
        var progress: Int = 0
        var completed: Bool = false
    }

    private static let weeklyChallengesKey = "com.clautch.weeklyChallenges"
    private static let weeklyDateKey = "com.clautch.weeklyDate"
    private(set) var weeklyChallenges: [WeeklyChallenge] = []
    private var weekStartDate: String = ""

    var completedWeeklyCount: Int {
        weeklyChallenges.filter(\.completed).count
    }

    private func loadWeeklyChallenges() {
        weekStartDate = UserDefaults.standard.string(forKey: Self.weeklyDateKey) ?? ""
        weeklyChallenges = Self.loadJSON(key: Self.weeklyChallengesKey) ?? []
        refreshWeeklyChallengesIfNeeded()
    }

    /// Returns the Monday of the current week as "yyyy-MM-dd".
    private static func mondayKey(for date: Date) -> String {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date) // 1=Sun, 2=Mon, ...
        let daysFromMonday = (weekday + 5) % 7 // 0=Mon, 1=Tue, ..., 6=Sun
        let monday = cal.date(byAdding: .day, value: -daysFromMonday, to: date)!
        return SessionStats.dateKey(for: monday)
    }

    private func refreshWeeklyChallengesIfNeeded() {
        let monday = Self.mondayKey(for: Date())
        guard weekStartDate != monday else { return }

        let pool: [(id: String, title: String, target: Int)] = [
            ("w_tools200",   "Use 200 tools this week",            200),
            ("w_tools500",   "Use 500 tools this week",            500),
            ("w_time300",    "Code for 5 hours this week",         300),
            ("w_time600",    "Code for 10 hours this week",        600),
            ("w_sessions10", "Complete 10 sessions this week",      10),
            ("w_days5",      "Code 5 days this week",                5),
            ("w_streak5",    "Maintain a 5-day streak",              5),
            ("w_reactions5",  "Send 5 reactions this week",          5),
        ]

        var seed = monday.hashValue
        var indices: Set<Int> = []
        while indices.count < 2 {
            seed = seed &* 6364136223846793005 &+ 1
            let idx = abs(seed) % pool.count
            indices.insert(idx)
        }

        weeklyChallenges = indices.sorted().map { idx in
            let c = pool[idx]
            return WeeklyChallenge(id: c.id, title: c.title, target: c.target)
        }
        weekStartDate = monday
        saveWeeklyChallenges()
    }

    /// Update weekly challenge progress. Called alongside daily quest updates.
    func updateWeeklyChallengeProgress() {
        refreshWeeklyChallengesIfNeeded()

        // Compute weekly totals from dailyTotals
        let cal = Calendar.current
        let today = Date()
        var weeklySeconds: TimeInterval = 0
        var activeDays = 0
        for offset in 0..<7 {
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            let key = SessionStats.dateKey(for: day)
            // Only count days within current week (back to Monday)
            if key >= weekStartDate {
                let secs = SessionStats.shared.dailyTotals[key] ?? 0
                weeklySeconds += secs
                if secs > 0 { activeDays += 1 }
            }
        }
        let weeklyMinutes = Int(weeklySeconds / 60)

        for i in weeklyChallenges.indices {
            guard !weeklyChallenges[i].completed else { continue }
            let oldProgress = weeklyChallenges[i].progress
            switch weeklyChallenges[i].id {
            case "w_tools200":   weeklyChallenges[i].progress = min(counters.totalToolUses, 200)
            case "w_tools500":   weeklyChallenges[i].progress = min(counters.totalToolUses, 500)
            case "w_time300":    weeklyChallenges[i].progress = min(weeklyMinutes, 300)
            case "w_time600":    weeklyChallenges[i].progress = min(weeklyMinutes, 600)
            case "w_sessions10": weeklyChallenges[i].progress = min(counters.totalSessions, 10)
            case "w_days5":      weeklyChallenges[i].progress = min(activeDays, 5)
            case "w_streak5":    weeklyChallenges[i].progress = min(streak.currentStreak, 5)
            case "w_reactions5": weeklyChallenges[i].progress = min(counters.totalReactionsSent, 5)
            default: break
            }

            if weeklyChallenges[i].progress >= weeklyChallenges[i].target && oldProgress < weeklyChallenges[i].target {
                weeklyChallenges[i].completed = true
                addXP(25)
                ActivityFeed.shared.add(icon: "🏆", text: "Weekly challenge: \(weeklyChallenges[i].title)")
            }
        }
        saveWeeklyChallenges()
    }

    private func saveWeeklyChallenges() {
        Self.saveJSON(weeklyChallenges, key: Self.weeklyChallengesKey)
        UserDefaults.standard.set(weekStartDate, forKey: Self.weeklyDateKey)
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

    private func savePrestige() {
        Self.saveJSON(prestige, key: Self.prestigeKey)
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
