import Foundation

/// A decoded event sent by a Claude Code hook via the Unix socket.
struct HookEvent: Codable, Sendable {
    let sessionId: String
    let eventType: EventType
    let toolName: String?
    let status: String?

    enum EventType: String, Codable, Sendable {
        case sessionStart    = "SessionStart"
        case sessionEnd      = "SessionEnd"
        case promptSubmit    = "UserPromptSubmit"
        case preToolUse      = "PreToolUse"
        case postToolUse     = "PostToolUse"
        case stop            = "Stop"
        case permissionRequest = "PermissionRequest"
        case preCompact      = "PreCompact"
    }

    /// Lenient decoder that handles Claude Code's actual JSON format.
    /// Claude Code sends `hook_event_name` (PascalCase) and `tool_response`
    /// instead of `event_type` (snake_case) and `status`.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: DynamicKey.self)

        // Session ID
        sessionId = try c.decodeIfPresent(String.self, forKey: .init("session_id"))
            ?? c.decodeIfPresent(String.self, forKey: .init("sessionId"))
            ?? UUID().uuidString

        // Event type: try hook_event_name (Claude Code format) then event_type (legacy)
        if let hookName = try c.decodeIfPresent(String.self, forKey: .init("hook_event_name")),
           let parsed = EventType(rawValue: hookName) {
            eventType = parsed
        } else if let legacyName = try c.decodeIfPresent(String.self, forKey: .init("event_type")) {
            // Support snake_case legacy format
            let mapped = Self.snakeToPascal(legacyName)
            eventType = EventType(rawValue: mapped) ?? .stop
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "No event type found"))
        }

        // Tool name
        toolName = try c.decodeIfPresent(String.self, forKey: .init("tool_name"))

        // Status: check top-level, then derive from tool_response
        if let directStatus = try c.decodeIfPresent(String.self, forKey: .init("status")) {
            status = directStatus
        } else if let response = try c.decodeIfPresent(ToolResponse.self, forKey: .init("tool_response")) {
            // Derive status from tool_response
            if response.interrupted == true {
                status = "error"
            } else if let stderr = response.stderr, !stderr.isEmpty {
                // Non-empty stderr could be a warning, not necessarily an error
                // Check exit code if available, otherwise treat as success
                status = "success"
            } else {
                status = "success"
            }
        } else {
            status = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: DynamicKey.self)
        try c.encode(sessionId, forKey: .init("session_id"))
        try c.encode(eventType, forKey: .init("hook_event_name"))
        try c.encodeIfPresent(toolName, forKey: .init("tool_name"))
        try c.encodeIfPresent(status, forKey: .init("status"))
    }

    /// Map snake_case event type to PascalCase for backward compat.
    private static func snakeToPascal(_ snake: String) -> String {
        switch snake {
        case "session_start":     return "SessionStart"
        case "session_end":       return "SessionEnd"
        case "user_prompt_submit": return "UserPromptSubmit"
        case "pre_tool_use":      return "PreToolUse"
        case "post_tool_use":     return "PostToolUse"
        case "stop":              return "Stop"
        case "permission_request": return "PermissionRequest"
        case "pre_compact":       return "PreCompact"
        default:                  return snake
        }
    }
}

/// Flexible coding key for dynamic JSON field access.
private struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    init(_ string: String) { self.stringValue = string }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}

/// Claude Code's tool_response structure.
private struct ToolResponse: Codable {
    let stdout: String?
    let stderr: String?
    let interrupted: Bool?
}
