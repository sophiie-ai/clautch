import XCTest
@testable import Clautch

@MainActor
final class SessionDataTests: XCTestCase {

    private func makeEvent(
        type: HookEvent.EventType,
        sessionId: String = "test-session",
        toolName: String? = nil,
        status: String? = nil
    ) -> HookEvent {
        let json: [String: Any?] = [
            "session_id": sessionId,
            "hook_event_name": type.rawValue,
            "tool_name": toolName,
            "status": status
        ]
        let data = try! JSONSerialization.data(withJSONObject: json.compactMapValues { $0 })
        return try! JSONDecoder().decode(HookEvent.self, from: data)
    }

    // MARK: - Task Transitions

    func testSessionStartSetsIdle() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(type: .sessionStart))
        XCTAssertEqual(session.state.task, .idle)
        XCTAssertEqual(session.state.emotion, .neutral)
    }

    func testPromptSubmitSetsThinking() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(type: .promptSubmit))
        XCTAssertEqual(session.state.task, .thinking)
    }

    func testPreToolUseSetsWorking() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(type: .preToolUse, toolName: "Bash"))
        XCTAssertEqual(session.state.task, .working)
        XCTAssertEqual(session.lastToolName, "Bash")
    }

    func testPostToolUseSetsThinking() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(type: .postToolUse, toolName: "Read", status: "success"))
        XCTAssertEqual(session.state.task, .thinking)
    }

    func testStopSetsIdle() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(type: .stop))
        XCTAssertEqual(session.state.task, .idle)
    }

    func testSessionEndSetsSleeping() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(type: .sessionEnd))
        XCTAssertEqual(session.state.task, .sleeping)
        XCTAssertEqual(session.state.emotion, .neutral)
    }

    func testPreCompactSetsCompacting() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(type: .preCompact))
        XCTAssertEqual(session.state.task, .compacting)
        XCTAssertEqual(session.state.emotion, .tired)
    }

    func testPermissionRequestSetsThinking() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(type: .permissionRequest))
        XCTAssertEqual(session.state.task, .thinking)
    }

    // MARK: - Emotion: Success / Error

    func testSuccessfulToolSetsHappy() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(type: .postToolUse, status: "success"))
        XCTAssertEqual(session.state.emotion, .happy)
    }

    func testSingleErrorSetsSad() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(type: .postToolUse, status: "error"))
        XCTAssertEqual(session.state.emotion, .sad)
    }

    func testFailureStatusSetsSad() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(type: .postToolUse, status: "failure"))
        XCTAssertEqual(session.state.emotion, .sad)
    }

    // MARK: - Emotion: Error Streak → Frustrated

    func testThreeConsecutiveErrorsSetsFrustrated() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(type: .postToolUse, status: "error"))
        session.applyEvent(makeEvent(type: .postToolUse, status: "error"))
        session.applyEvent(makeEvent(type: .postToolUse, status: "error"))
        XCTAssertEqual(session.state.emotion, .frustrated)
    }

    func testSuccessResetsErrorStreak() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(type: .postToolUse, status: "error"))
        session.applyEvent(makeEvent(type: .postToolUse, status: "error"))
        session.applyEvent(makeEvent(type: .postToolUse, status: "success"))
        // Streak reset, next error should be sad not frustrated
        session.applyEvent(makeEvent(type: .postToolUse, status: "error"))
        XCTAssertEqual(session.state.emotion, .sad)
    }

    // MARK: - Emotion: Permission Requests → Confused

    func testThreePermissionRequestsSetsConfused() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(type: .permissionRequest))
        session.applyEvent(makeEvent(type: .permissionRequest))
        XCTAssertNotEqual(session.state.emotion, .confused)
        session.applyEvent(makeEvent(type: .permissionRequest))
        XCTAssertEqual(session.state.emotion, .confused)
    }

    // MARK: - Emotion: Stop

    func testShortSessionStopSetsHappy() {
        let session = SessionData(id: "s1")
        // Session just started, so stop is a "short session"
        session.applyEvent(makeEvent(type: .stop))
        XCTAssertEqual(session.state.emotion, .happy)
    }

    // MARK: - Last Activity Updates

    func testEventsUpdateLastActivity() {
        let session = SessionData(id: "s1")
        let before = session.state.lastActivity
        // Small delay to ensure time difference
        session.applyEvent(makeEvent(type: .preToolUse, toolName: "Edit"))
        XCTAssertGreaterThanOrEqual(session.state.lastActivity, before)
    }

    // MARK: - Session Start Resets Error Streak

    func testSessionStartResetsErrorStreak() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(type: .postToolUse, status: "error"))
        session.applyEvent(makeEvent(type: .postToolUse, status: "error"))
        session.applyEvent(makeEvent(type: .sessionStart))
        // After reset, one more error should be sad, not frustrated
        session.applyEvent(makeEvent(type: .postToolUse, status: "error"))
        XCTAssertEqual(session.state.emotion, .sad)
    }
}
