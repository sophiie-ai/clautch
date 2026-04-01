import XCTest
@testable import Clautch

final class HookEventTests: XCTestCase {

    // MARK: - Claude Code format (hook_event_name, PascalCase)

    func testDecodeClaudeCodeFormat() throws {
        let json = """
        {"session_id": "abc123", "hook_event_name": "PreToolUse", "tool_name": "Bash"}
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(HookEvent.self, from: json)
        XCTAssertEqual(event.sessionId, "abc123")
        XCTAssertEqual(event.eventType, .preToolUse)
        XCTAssertEqual(event.toolName, "Bash")
    }

    func testDecodePostToolUseWithResponse() throws {
        let json = """
        {"session_id": "abc", "hook_event_name": "PostToolUse", "tool_name": "Read", "tool_response": {"stdout": "file contents", "stderr": "", "interrupted": false}}
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(HookEvent.self, from: json)
        XCTAssertEqual(event.eventType, .postToolUse)
        XCTAssertEqual(event.status, "success")
    }

    func testDecodePostToolUseInterrupted() throws {
        let json = """
        {"session_id": "abc", "hook_event_name": "PostToolUse", "tool_name": "Bash", "tool_response": {"stdout": "", "stderr": "killed", "interrupted": true}}
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(HookEvent.self, from: json)
        XCTAssertEqual(event.status, "error")
    }

    func testDecodeStopEvent() throws {
        let json = """
        {"session_id": "abc", "hook_event_name": "Stop", "stop_hook_active": false}
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(HookEvent.self, from: json)
        XCTAssertEqual(event.eventType, .stop)
    }

    // MARK: - Legacy format (event_type, snake_case)

    func testDecodeLegacyFormat() throws {
        let json = """
        {"session_id": "abc123", "event_type": "session_start"}
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(HookEvent.self, from: json)
        XCTAssertEqual(event.sessionId, "abc123")
        XCTAssertEqual(event.eventType, .sessionStart)
    }

    func testDecodeLegacyToolEvent() throws {
        let json = """
        {"session_id": "abc", "event_type": "post_tool_use", "tool_name": "Read", "status": "success"}
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(HookEvent.self, from: json)
        XCTAssertEqual(event.eventType, .postToolUse)
        XCTAssertEqual(event.toolName, "Read")
        XCTAssertEqual(event.status, "success")
    }

    func testDecodeMissingSessionId() throws {
        let json = """
        {"hook_event_name": "Stop"}
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(HookEvent.self, from: json)
        XCTAssertEqual(event.eventType, .stop)
        XCTAssertFalse(event.sessionId.isEmpty)
    }

    func testAllEventTypes() {
        let types: [HookEvent.EventType] = [
            .sessionStart, .sessionEnd, .promptSubmit, .preToolUse,
            .postToolUse, .stop, .permissionRequest, .preCompact
        ]
        for type in types {
            XCTAssertFalse(type.rawValue.isEmpty)
        }
    }
}
