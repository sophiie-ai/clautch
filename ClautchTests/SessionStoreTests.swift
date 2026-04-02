import XCTest
@testable import Clautch

@MainActor
final class SessionStoreTests: XCTestCase {

    // MARK: - getOrCreate

    func testGetOrCreateNewSession() {
        let store = SessionStore()
        let session = store.getOrCreate(id: "abc")
        XCTAssertEqual(session.id, "abc")
        XCTAssertEqual(store.sessions.count, 1)
    }

    func testGetOrCreateReusesExisting() {
        let store = SessionStore()
        let first = store.getOrCreate(id: "abc")
        let second = store.getOrCreate(id: "abc")
        XCTAssertTrue(first === second)
        XCTAssertEqual(store.sessions.count, 1)
    }

    func testGetOrCreateMultipleSessions() {
        let store = SessionStore()
        _ = store.getOrCreate(id: "a")
        _ = store.getOrCreate(id: "b")
        _ = store.getOrCreate(id: "c")
        XCTAssertEqual(store.sessions.count, 3)
    }

    // MARK: - activeSessions

    func testActiveSessionsFiltersStale() {
        let store = SessionStore()
        let fresh = store.getOrCreate(id: "fresh")
        fresh.state.lastActivity = Date()

        let stale = store.getOrCreate(id: "stale")
        stale.state.lastActivity = Date(timeIntervalSinceNow: -120) // 2 min ago

        store.invalidateCache()
        XCTAssertEqual(store.activeSessions.count, 1)
        XCTAssertEqual(store.activeSessions.first?.id, "fresh")
    }

    // MARK: - effectiveSession

    func testEffectiveSessionIsMostRecent() {
        let store = SessionStore()
        let older = store.getOrCreate(id: "older")
        older.state.lastActivity = Date(timeIntervalSinceNow: -10)

        let newer = store.getOrCreate(id: "newer")
        newer.state.lastActivity = Date()

        store.invalidateCache()
        XCTAssertEqual(store.effectiveSession?.id, "newer")
    }

    func testEffectiveSessionNilWhenEmpty() {
        let store = SessionStore()
        XCTAssertNil(store.effectiveSession)
    }

    func testEffectiveSessionNilWhenAllStale() {
        let store = SessionStore()
        let s = store.getOrCreate(id: "old")
        s.state.lastActivity = Date(timeIntervalSinceNow: -120)
        store.invalidateCache()
        XCTAssertNil(store.effectiveSession)
    }

    // MARK: - markInactive

    func testMarkInactiveSetsSleeping() {
        let store = SessionStore()
        let session = store.getOrCreate(id: "s1")
        session.state.task = .working
        store.markInactive(id: "s1")
        XCTAssertEqual(session.state.task, .sleeping)
    }

    func testMarkInactiveIgnoresUnknownId() {
        let store = SessionStore()
        // Should not crash
        store.markInactive(id: "nonexistent")
    }

    // MARK: - cleanupStale

    func testCleanupRemovesOldSessions() {
        let store = SessionStore()
        let stale = store.getOrCreate(id: "stale")
        stale.state.lastActivity = Date(timeIntervalSinceNow: -400) // >5 min

        let fresh = store.getOrCreate(id: "fresh")
        fresh.state.lastActivity = Date()

        store.cleanupStale()
        XCTAssertEqual(store.sessions.count, 1)
        XCTAssertEqual(store.sessions.first?.id, "fresh")
    }

    func testCleanupKeepsRecentSessions() {
        let store = SessionStore()
        let s = store.getOrCreate(id: "recent")
        s.state.lastActivity = Date(timeIntervalSinceNow: -200) // 3.3 min, within 5 min window
        store.cleanupStale()
        XCTAssertEqual(store.sessions.count, 1)
    }
}
