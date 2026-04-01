import XCTest
@testable import Clautch

final class HookEventTests: XCTestCase {

    func testDecodeBasicEvent() throws {
        let json = """
        {"session_id": "abc123", "event_type": "session_start"}
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(HookEvent.self, from: json)
        XCTAssertEqual(event.sessionId, "abc123")
        XCTAssertEqual(event.eventType, .sessionStart)
        XCTAssertNil(event.toolName)
        XCTAssertNil(event.status)
    }

    func testDecodeToolEvent() throws {
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
        {"event_type": "stop"}
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(HookEvent.self, from: json)
        XCTAssertEqual(event.eventType, .stop)
        // sessionId should get a UUID fallback
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
