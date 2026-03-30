import Foundation

/// A decoded event sent by a Claude Code hook via the Unix socket.
struct HookEvent: Codable, Sendable {
    let sessionId: String
    let eventType: EventType
    let toolName: String?
    let status: String?

    enum EventType: String, Codable, Sendable {
        case sessionStart    = "session_start"
        case sessionEnd      = "session_end"
        case promptSubmit    = "user_prompt_submit"
        case preToolUse      = "pre_tool_use"
        case postToolUse     = "post_tool_use"
        case stop            = "stop"
        case permissionRequest = "permission_request"
        case preCompact      = "pre_compact"
    }

    enum CodingKeys: String, CodingKey {
        case sessionId   = "session_id"
        case eventType   = "event_type"
        case toolName    = "tool_name"
        case status
    }

    /// Lenient decoder that falls back gracefully for unknown event types.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try c.decodeIfPresent(String.self, forKey: .sessionId) ?? UUID().uuidString
        eventType = try c.decode(EventType.self, forKey: .eventType)
        toolName  = try c.decodeIfPresent(String.self, forKey: .toolName)
        status    = try c.decodeIfPresent(String.self, forKey: .status)
    }
}
