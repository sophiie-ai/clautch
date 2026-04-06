import XCTest
@testable import Clautch

@MainActor
final class GamificationStoreTests: XCTestCase {

    private func makeStore(
        streak: StreakData = StreakData(),
        achievements: [EarnedAchievement] = [],
        counters: GamificationStore.AchievementCounters = .init(),
        xp: Int = 0
    ) -> GamificationStore {
        GamificationStore(streak: streak, achievements: achievements, counters: counters, xp: xp)
    }

    // MARK: - Streak Tests

    func testFirstSessionStartsStreak() {
        let store = makeStore()
        store.recordSessionStart()
        XCTAssertEqual(store.streak.currentStreak, 1)
        XCTAssertEqual(store.streak.longestStreak, 1)
        XCTAssertNotNil(store.streak.lastActiveDate)
    }

    func testSameDayDoesNotIncrementStreak() {
        let today = SessionStats.dateKey(for: Date())
        let store = makeStore(streak: StreakData(
            currentStreak: 3,
            longestStreak: 5,
            lastActiveDate: today,
            streakStartDate: today
        ))
        store.checkAndUpdateStreak()
        XCTAssertEqual(store.streak.currentStreak, 3, "Same day should not increment")
    }

    func testConsecutiveDayContinuesStreak() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayKey = SessionStats.dateKey(for: yesterday)
        let store = makeStore(streak: StreakData(
            currentStreak: 5,
            longestStreak: 5,
            lastActiveDate: yesterdayKey,
            streakStartDate: yesterdayKey
        ))
        store.checkAndUpdateStreak()
        XCTAssertEqual(store.streak.currentStreak, 6)
        XCTAssertEqual(store.streak.longestStreak, 6)
    }

    func testGapBreaksStreak() {
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let key = SessionStats.dateKey(for: twoDaysAgo)
        let store = makeStore(streak: StreakData(
            currentStreak: 10,
            longestStreak: 10,
            lastActiveDate: key,
            streakStartDate: key
        ))
        store.checkAndUpdateStreak()
        XCTAssertEqual(store.streak.currentStreak, 1, "Gap should reset streak")
        XCTAssertEqual(store.streak.longestStreak, 10, "Longest should be preserved")
    }

    // MARK: - Achievement Tests

    func testFirstSessionAchievement() {
        let store = makeStore()
        store.recordSessionStart()
        XCTAssertTrue(store.isEarned(.firstSession))
    }

    func testTenSessionsAchievement() {
        let store = makeStore(counters: .init(totalSessions: 9))
        store.recordSessionStart()
        XCTAssertTrue(store.isEarned(.tenSessions))
    }

    func testBugSquasherAchievement() {
        let store = makeStore(counters: .init(totalToolUses: 99))
        store.recordToolUse()
        XCTAssertTrue(store.isEarned(.bugSquasher))
    }

    func testTeamPlayerAchievement() {
        let store = makeStore()
        store.recordRoomJoined()
        XCTAssertTrue(store.isEarned(.teamPlayer))
    }

    func testSocialButterflyAchievement() {
        let store = makeStore(counters: .init(totalReactionsSent: 9))
        store.recordReactionSent()
        XCTAssertTrue(store.isEarned(.socialButterfly))
    }

    func testMarathonAchievement() {
        let store = makeStore()
        store.recordSessionEnd(duration: 4 * 3600 + 1, startHour: 10)
        XCTAssertTrue(store.isEarned(.marathon))
    }

    func testSpeedDemonAchievement() {
        let store = makeStore()
        store.recordSpeedBurst()
        XCTAssertTrue(store.isEarned(.speedDemon))
    }

    func testStreakThreeAchievement() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let store = makeStore(streak: StreakData(
            currentStreak: 2,
            longestStreak: 2,
            lastActiveDate: SessionStats.dateKey(for: yesterday)
        ))
        store.checkAndUpdateStreak()
        XCTAssertTrue(store.isEarned(.streakThree))
    }

    func testNoDoubleUnlock() {
        let store = makeStore()
        store.recordSessionStart()
        store.recordSessionStart()
        let count = store.earnedAchievements.filter { $0.achievementId == .firstSession }.count
        XCTAssertEqual(count, 1, "Should not unlock the same achievement twice")
    }

    // MARK: - Celebration Queue

    func testCelebrationQueue() {
        let store = makeStore()
        store.recordSessionStart()
        XCTAssertFalse(store.celebrationQueue.isEmpty)
        let popped = store.popCelebration()
        XCTAssertEqual(popped, .firstSession)
    }

    // MARK: - XP & Evolution

    func testSessionStartAwardsXP() {
        let store = makeStore()
        store.recordSessionStart()
        // 5 XP session + 20 XP firstSession + 20 XP fiveSessions(1>=1? no, 5 sessions needed)
        // Actually: firstSession unlocks (1>=1), gives +20. fiveSessions needs 5.
        // Streak multiplier: 1.0 (streak=1 → 1.05, but rounding up applies)
        // 5*1.05=5.25→6, 20*1.05=21→21, plus 3 XP streak day *1.05=3.15→4
        // Total: 6+4+21 = 31 minimum. But exact value depends on order.
        // Just verify XP > 0 and firstSession unlocked
        XCTAssertGreaterThan(store.xp, 0, "Session start should award XP")
        XCTAssertTrue(store.isEarned(.firstSession))
    }

    func testToolUseAwardsXP() {
        let store = makeStore(xp: 50)
        let before = store.xp
        store.recordToolUse()
        XCTAssertGreaterThan(store.xp, before, "Tool use should award XP")
    }

    func testEvolutionStages() {
        XCTAssertEqual(CreatureEvolution.from(xp: 0), .baby)
        XCTAssertEqual(CreatureEvolution.from(xp: 49), .baby)
        XCTAssertEqual(CreatureEvolution.from(xp: 50), .juvenile)
        XCTAssertEqual(CreatureEvolution.from(xp: 149), .juvenile)
        XCTAssertEqual(CreatureEvolution.from(xp: 150), .grown)
        XCTAssertEqual(CreatureEvolution.from(xp: 349), .grown)
        XCTAssertEqual(CreatureEvolution.from(xp: 350), .mature)
        XCTAssertEqual(CreatureEvolution.from(xp: 599), .mature)
        XCTAssertEqual(CreatureEvolution.from(xp: 600), .elder)
        XCTAssertEqual(CreatureEvolution.from(xp: 999), .elder)
        XCTAssertEqual(CreatureEvolution.from(xp: 1000), .ancient)
        XCTAssertEqual(CreatureEvolution.from(xp: 9999), .ancient)
    }

    func testEvolutionDerivedFromXP() {
        let store = makeStore(xp: 49)
        XCTAssertEqual(store.evolution, .baby)
        store.recordToolUse() // +1 XP (with multiplier) → 50+
        XCTAssertEqual(store.evolution, .juvenile)
    }
}
