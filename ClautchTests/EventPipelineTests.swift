import XCTest
@testable import Clautch

/// End-to-end tests for the event pipeline: HookEvent → SessionData → CreatureState.
@MainActor
final class EventPipelineTests: XCTestCase {

    private func makeEvent(_ type: HookEvent.EventType, session: String = "test-session", tool: String? = nil, status: String? = nil) -> HookEvent {
        // Use the encode/decode path to create events properly
        let json: [String: Any] = [
            "hook_event_name": type.rawValue,
            "session_id": session,
            "tool_name": tool as Any,
            "status": status as Any,
        ].compactMapValues { $0 }
        let data = try! JSONSerialization.data(withJSONObject: json)
        return try! JSONDecoder().decode(HookEvent.self, from: data)
    }

    // MARK: - Full Pipeline

    func testSessionStartSetsIdle() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(.sessionStart))
        XCTAssertEqual(session.state.task, .idle)
        XCTAssertEqual(session.state.emotion, .neutral)
        XCTAssertFalse(session.state.needsInput)
        XCTAssertFalse(session.state.needsPermission)
    }

    func testPromptSubmitSetsThinking() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(.promptSubmit))
        XCTAssertEqual(session.state.task, .thinking)
    }

    func testPreToolUseSetsWorking() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(.preToolUse, tool: "Read"))
        XCTAssertEqual(session.state.task, .working)
        XCTAssertEqual(session.lastToolName, "Read")
    }

    func testPostToolUseSetsThinking() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(.postToolUse, tool: "Write", status: "success"))
        XCTAssertEqual(session.state.task, .thinking)
        XCTAssertEqual(session.state.emotion, .happy)
    }

    func testStopSetsIdleAndNeedsInput() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(.sessionStart))
        session.applyEvent(makeEvent(.preToolUse, tool: "Read"))
        session.applyEvent(makeEvent(.stop))
        XCTAssertEqual(session.state.task, .idle)
        XCTAssertTrue(session.state.needsInput)
    }

    func testPromptClearsNeedsInput() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(.stop))
        XCTAssertTrue(session.state.needsInput)
        session.applyEvent(makeEvent(.promptSubmit))
        XCTAssertFalse(session.state.needsInput)
    }

    func testSessionEndSetsSleeping() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(.sessionEnd))
        XCTAssertEqual(session.state.task, .sleeping)
        XCTAssertEqual(session.state.emotion, .neutral)
    }

    func testPreCompactSetsCompacting() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(.preCompact))
        XCTAssertEqual(session.state.task, .compacting)
        XCTAssertEqual(session.state.emotion, .tired)
    }

    func testPermissionRequestSetsNeedsPermission() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(.permissionRequest))
        XCTAssertEqual(session.state.task, .thinking)
        XCTAssertTrue(session.state.needsPermission)
    }

    func testPromptClearsNeedsPermission() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(.permissionRequest))
        XCTAssertTrue(session.state.needsPermission)
        session.applyEvent(makeEvent(.promptSubmit))
        XCTAssertFalse(session.state.needsPermission)
    }

    // MARK: - Error Streaks

    func testErrorStreakSetsFrustrated() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(.postToolUse, status: "error"))
        session.applyEvent(makeEvent(.postToolUse, status: "error"))
        session.applyEvent(makeEvent(.postToolUse, status: "error"))
        XCTAssertEqual(session.state.emotion, .frustrated)
    }

    func testSuccessResetsErrorStreak() {
        let session = SessionData(id: "s1")
        session.applyEvent(makeEvent(.postToolUse, status: "error"))
        session.applyEvent(makeEvent(.postToolUse, status: "error"))
        session.applyEvent(makeEvent(.postToolUse, status: "success"))
        XCTAssertEqual(session.state.emotion, .happy)
    }

    // MARK: - Full Lifecycle

    func testFullSessionLifecycle() {
        let session = SessionData(id: "lifecycle")

        // Start
        session.applyEvent(makeEvent(.sessionStart, session: "lifecycle"))
        XCTAssertEqual(session.state.task, .idle)

        // User types
        session.applyEvent(makeEvent(.promptSubmit, session: "lifecycle"))
        XCTAssertEqual(session.state.task, .thinking)
        XCTAssertFalse(session.state.needsInput)

        // Agent works
        session.applyEvent(makeEvent(.preToolUse, session: "lifecycle", tool: "Bash"))
        XCTAssertEqual(session.state.task, .working)

        session.applyEvent(makeEvent(.postToolUse, session: "lifecycle", tool: "Bash", status: "success"))
        XCTAssertEqual(session.state.task, .thinking)

        // Agent done
        session.applyEvent(makeEvent(.stop, session: "lifecycle"))
        XCTAssertEqual(session.state.task, .idle)
        XCTAssertTrue(session.state.needsInput)

        // User responds
        session.applyEvent(makeEvent(.promptSubmit, session: "lifecycle"))
        XCTAssertFalse(session.state.needsInput)

        // Permission needed
        session.applyEvent(makeEvent(.permissionRequest, session: "lifecycle"))
        XCTAssertTrue(session.state.needsPermission)

        // Session ends
        session.applyEvent(makeEvent(.sessionEnd, session: "lifecycle"))
        XCTAssertEqual(session.state.task, .sleeping)
    }
}
