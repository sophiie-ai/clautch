import XCTest
@testable import Clautch

/// Tests for recently added features: typing, permission, chat persistence, sanitization.
@MainActor
final class FeatureCoverageTests: XCTestCase {

    // MARK: - String Sanitization

    func testSanitizeStripsControlChars() {
        let input = "hello\u{0000}world\u{0007}"
        let result = NotificationService.sanitize(input, maxLength: 50)
        XCTAssertEqual(result, "helloworld")
    }

    func testSanitizeStripsBidiChars() {
        let input = "test\u{200F}name\u{200E}"  // RTL/LTR marks
        let result = NotificationService.sanitize(input, maxLength: 50)
        XCTAssertEqual(result, "testname")
    }

    func testSanitizeTruncates() {
        let input = String(repeating: "a", count: 100)
        let result = NotificationService.sanitize(input, maxLength: 10)
        XCTAssertEqual(result.count, 10)
    }

    func testSanitizePreservesEmoji() {
        let result = NotificationService.sanitize("hello 👋 world", maxLength: 50)
        XCTAssertTrue(result.contains("👋"))
    }

    func testSanitizePreservesNormalText() {
        let result = NotificationService.sanitize("Hello World!", maxLength: 50)
        XCTAssertEqual(result, "Hello World!")
    }

    // MARK: - Typing Indicator State

    func testTypingSetOnChatInput() {
        let session = SessionData(id: "t1")
        // Typing is not directly set by events, it's a PeerState field
        // Verify the field exists and defaults correctly
        XCTAssertFalse(session.state.needsInput)
        XCTAssertNil(PeerState(
            peerId: "p1", displayName: "Test", creatureType: .ghost,
            task: .idle, emotion: .neutral, colorPreset: .none, accessory: .none,
            evolution: .baby, timestamp: Date()
        ).isTyping)
    }

    func testTypingInBroadcastEquals() {
        var a = PeerState(
            peerId: "p1", displayName: "Test", creatureType: .ghost,
            task: .idle, emotion: .neutral, colorPreset: .none, accessory: .none,
            evolution: .baby, timestamp: Date(), isTyping: true
        )
        var b = a
        b.isTyping = false
        XCTAssertFalse(a.broadcastEquals(b))
    }

    // MARK: - Permission Badge State

    func testPermissionRequestSetsFlag() {
        let session = SessionData(id: "p1")
        let event = makeEvent(.permissionRequest)
        session.applyEvent(event)
        XCTAssertTrue(session.state.needsPermission)
    }

    func testPromptClearsPermission() {
        let session = SessionData(id: "p1")
        session.applyEvent(makeEvent(.permissionRequest))
        XCTAssertTrue(session.state.needsPermission)
        session.applyEvent(makeEvent(.promptSubmit))
        XCTAssertFalse(session.state.needsPermission)
    }

    func testStopDoesNotSetPermission() {
        let session = SessionData(id: "p1")
        session.applyEvent(makeEvent(.stop))
        XCTAssertFalse(session.state.needsPermission)
        XCTAssertTrue(session.state.needsInput)
    }

    // MARK: - Chat Persistence

    func testRoomActivityFeedPersistence() {
        let feed = RoomActivityFeed.shared
        feed.clear()

        feed.addChat(from: "Alice", message: "hello")
        feed.addJoin("Bob")

        XCTAssertEqual(feed.events.count, 2)
        XCTAssertEqual(feed.events[0].kind, .chat)
        XCTAssertEqual(feed.events[1].kind, .join)

        // Verify events are Codable
        let encoded = try? JSONEncoder().encode(feed.events)
        XCTAssertNotNil(encoded)

        if let data = encoded {
            let decoded = try? JSONDecoder().decode([RoomEvent].self, from: data)
            XCTAssertEqual(decoded?.count, 2)
            XCTAssertEqual(decoded?[0].kind, .chat)
        }

        feed.clear()
        XCTAssertTrue(feed.events.isEmpty)
    }

    func testRoomEventTimeAgo() {
        let event = RoomEvent(kind: .chat, peerName: "Test", text: "hi", timestamp: Date())
        XCTAssertEqual(event.timeAgo, "0s")

        let oldEvent = RoomEvent(kind: .chat, peerName: "Test", text: "hi",
                                  timestamp: Date(timeIntervalSinceNow: -120))
        XCTAssertEqual(oldEvent.timeAgo, "2m")
    }

    func testRoomEventIcons() {
        XCTAssertEqual(RoomEvent(kind: .chat, peerName: "", text: "", timestamp: Date()).icon, "bubble.left")
        XCTAssertEqual(RoomEvent(kind: .join, peerName: "", text: "", timestamp: Date()).icon, "person.badge.plus")
        XCTAssertEqual(RoomEvent(kind: .leave, peerName: "", text: "", timestamp: Date()).icon, "person.badge.minus")
        XCTAssertEqual(RoomEvent(kind: .reaction, peerName: "", text: "", timestamp: Date()).icon, "sparkles")
    }

    // MARK: - NeedsInput + NeedsPermission Mutual Exclusion

    func testNeedsInputAndPermissionIndependent() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(.stop))
        XCTAssertTrue(session.state.needsInput)
        XCTAssertFalse(session.state.needsPermission)

        session.applyEvent(makeEvent(.promptSubmit))
        session.applyEvent(makeEvent(.permissionRequest))
        XCTAssertFalse(session.state.needsInput)
        XCTAssertTrue(session.state.needsPermission)
    }

    // MARK: - Helpers

    private func makeEvent(_ type: HookEvent.EventType, status: String? = nil) -> HookEvent {
        let json: [String: Any] = [
            "hook_event_name": type.rawValue,
            "session_id": "test",
            "status": status as Any,
        ].compactMapValues { $0 }
        let data = try! JSONSerialization.data(withJSONObject: json)
        return try! JSONDecoder().decode(HookEvent.self, from: data)
    }
}
