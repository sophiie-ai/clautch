import Foundation

// MARK: - Task

/// What the creature is doing — driven by Claude Code hook events.
enum CreatureTask: String, Codable, Sendable {
    case idle
    case working
    case thinking
    case sleeping
    case compacting

    /// Vertical bob period in seconds.
    var bobPeriod: Double {
        switch self {
        case .idle:       return 1.5
        case .working:    return 0.4
        case .thinking:   return 1.0
        case .sleeping:   return 4.0
        case .compacting: return 0.5
        }
    }

    /// Vertical bob amplitude in points.
    var bobAmplitude: Double {
        switch self {
        case .idle:       return 1.5
        case .working:    return 0.5
        case .thinking:   return 0.8
        case .sleeping:   return 0.0
        case .compacting: return 0.0
        }
    }

    /// Human-readable label for display.
    var displayLabel: String {
        switch self {
        case .idle:       return "Idle"
        case .working:    return "Working"
        case .thinking:   return "Thinking"
        case .sleeping:   return "Sleeping"
        case .compacting: return "Compacting"
        }
    }

    /// Frames per second for sprite sheet animation.
    var fps: Double {
        switch self {
        case .idle:       return 3
        case .working:    return 5
        case .thinking:   return 2
        case .sleeping:   return 1.5
        case .compacting: return 6
        }
    }
}

// MARK: - Emotion

/// The creature's emotional state — derived from Claude Code event patterns.
enum CreatureEmotion: String, Codable, Sendable {
    case neutral
    case happy       // successful completions, tools working
    case sad         // single error
    case frustrated  // multiple consecutive errors
    case excited     // rapid successful tool use
    case confused    // permission requests, retries
    case tired       // long session, after compacting
}

// MARK: - Composite State

/// Full state of a creature: what it's doing + how it feels.
struct CreatureState: Sendable {
    var task: CreatureTask       = .idle
    var emotion: CreatureEmotion = .neutral
    var lastActivity: Date       = Date()
    var needsInput: Bool         = false
    var needsPermission: Bool    = false

    /// Whether the creature has had activity in the last 60 seconds.
    var isActive: Bool {
        Date().timeIntervalSince(lastActivity) < 60
    }
}
