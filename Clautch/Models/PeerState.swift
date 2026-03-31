import Foundation

/// Quick reactions peers can send to each other.
enum PeerReaction: String, Codable, Sendable, CaseIterable, Identifiable {
    case wave       // 👋
    case celebrate  // 🎉
    case heart      // ❤️
    case fire       // 🔥
    case eyes       // 👀
    case thumbsUp   // 👍

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .wave:      return "👋"
        case .celebrate: return "🎉"
        case .heart:     return "❤️"
        case .fire:      return "🔥"
        case .eyes:      return "👀"
        case .thumbsUp:  return "👍"
        }
    }
}

/// The state broadcast to other peers — intentionally abstract for privacy.
/// No file paths, prompts, or code content.
struct PeerState: Codable, Sendable, Identifiable {
    let peerId: String
    let displayName: String
    let creatureType: CreatureType
    let task: CreatureTask
    let emotion: CreatureEmotion
    let colorPreset: CreatureColorPreset
    let accessory: CreatureAccessory
    let timestamp: Date
    var reaction: PeerReaction?
    var reactionTimestamp: Date?
    var chatMessage: String?
    var chatTimestamp: Date?

    var id: String { peerId }

    /// Whether this peer has been active recently.
    var isActive: Bool {
        Date().timeIntervalSince(timestamp) < 60
    }

    /// Whether this peer should still be shown (active within 5 min).
    var isVisible: Bool {
        Date().timeIntervalSince(timestamp) < 300
    }

    /// Whether the reaction is still fresh (show for 4 seconds).
    var hasActiveReaction: Bool {
        guard let rt = reactionTimestamp else { return false }
        return Date().timeIntervalSince(rt) < 4
    }

    /// Whether the chat message is still fresh (show for 8 seconds).
    var hasActiveChat: Bool {
        guard let ct = chatTimestamp else { return false }
        return Date().timeIntervalSince(ct) < 8
    }

    /// The active chat message, if still fresh.
    var activeChatMessage: String? {
        hasActiveChat ? chatMessage : nil
    }
}

// MARK: - Unified Creature Display

/// A single creature to render — could be local (from SessionStore) or remote (from PeerStore).
struct CreatureDisplay: Identifiable {
    let id: String
    let state: CreatureState
    let creatureType: CreatureType
    let colorPreset: CreatureColorPreset
    let accessory: CreatureAccessory
    let xPosition: CGFloat
    let isLocal: Bool
    let displayName: String
    var sessionDuration: TimeInterval?
    var lastToolName: String?
    var facingRight: Bool = true
    var reaction: PeerReaction?
    var reactionActive: Bool = false
    var chatMessage: String?
}
