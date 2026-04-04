import Foundation
import SwiftUI

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

    /// 5×5 pixel art for the reaction. 0=clear, 1=primary, 2=secondary.
    var pixels: [[Int]] {
        switch self {
        case .wave:
            return [
                [0,1,0,1,0],
                [1,1,1,1,1],
                [0,1,1,1,0],
                [0,0,1,0,0],
                [0,0,1,0,0],
            ]
        case .celebrate:
            return [
                [1,0,1,0,1],
                [0,2,2,2,0],
                [1,2,2,2,1],
                [0,2,2,2,0],
                [1,0,1,0,1],
            ]
        case .heart:
            return [
                [0,1,0,1,0],
                [1,1,1,1,1],
                [1,1,1,1,1],
                [0,1,1,1,0],
                [0,0,1,0,0],
            ]
        case .fire:
            return [
                [0,0,2,0,0],
                [0,2,1,0,0],
                [0,1,1,1,0],
                [1,1,1,1,1],
                [0,1,1,1,0],
            ]
        case .eyes:
            return [
                [0,0,0,0,0],
                [1,1,0,1,1],
                [2,1,0,2,1],
                [1,1,0,1,1],
                [0,0,0,0,0],
            ]
        case .thumbsUp:
            return [
                [0,0,1,1,0],
                [0,1,1,1,0],
                [1,1,1,1,0],
                [1,1,1,1,0],
                [0,1,1,0,0],
            ]
        }
    }

    var primaryColor: Color {
        switch self {
        case .wave:      return Color(red: 1.0, green: 0.85, blue: 0.5)
        case .celebrate: return Color(red: 1.0, green: 0.85, blue: 0.1)
        case .heart:     return Color(red: 1.0, green: 0.25, blue: 0.35)
        case .fire:      return Color(red: 1.0, green: 0.5, blue: 0.0)
        case .eyes:      return Color.white
        case .thumbsUp:  return Color(red: 1.0, green: 0.85, blue: 0.5)
        }
    }

    var secondaryColor: Color {
        switch self {
        case .wave:      return Color(red: 1.0, green: 0.7, blue: 0.3)
        case .celebrate: return Color.white
        case .heart:     return Color(red: 1.0, green: 0.5, blue: 0.6)
        case .fire:      return Color(red: 1.0, green: 0.9, blue: 0.2)
        case .eyes:      return Color(red: 0.2, green: 0.2, blue: 0.2)
        case .thumbsUp:  return Color(red: 1.0, green: 0.7, blue: 0.3)
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
    let evolution: CreatureEvolution
    let timestamp: Date
    var xPosition: CGFloat?
    var publicKey: String?
    var signature: String?
    var reaction: PeerReaction?
    var reactionTimestamp: Date?
    var chatMessage: String?
    var chatTimestamp: Date?
    var isTyping: Bool?

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

    /// Whether the broadcast-relevant fields match another state.
    func broadcastEquals(_ other: PeerState) -> Bool {
        peerId == other.peerId &&
        displayName == other.displayName &&
        creatureType == other.creatureType &&
        task == other.task &&
        emotion == other.emotion &&
        colorPreset == other.colorPreset &&
        accessory == other.accessory &&
        evolution == other.evolution &&
        reaction == other.reaction &&
        chatMessage == other.chatMessage &&
        isTyping == other.isTyping &&
        abs((xPosition ?? 0.5) - (other.xPosition ?? 0.5)) < 0.01
    }
}

// MARK: - Backward-Compatible Decoding

extension PeerState {
    /// Default evolution to .baby for peers that don't have the field yet.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        peerId = try c.decode(String.self, forKey: .peerId)
        displayName = try c.decode(String.self, forKey: .displayName)
        creatureType = try c.decode(CreatureType.self, forKey: .creatureType)
        task = try c.decode(CreatureTask.self, forKey: .task)
        emotion = try c.decode(CreatureEmotion.self, forKey: .emotion)
        colorPreset = try c.decode(CreatureColorPreset.self, forKey: .colorPreset)
        accessory = try c.decodeIfPresent(CreatureAccessory.self, forKey: .accessory) ?? .none
        evolution = try c.decodeIfPresent(CreatureEvolution.self, forKey: .evolution) ?? .baby
        timestamp = try c.decode(Date.self, forKey: .timestamp)
        xPosition = try c.decodeIfPresent(CGFloat.self, forKey: .xPosition)
        publicKey = try c.decodeIfPresent(String.self, forKey: .publicKey)
        signature = try c.decodeIfPresent(String.self, forKey: .signature)
        reaction = try c.decodeIfPresent(PeerReaction.self, forKey: .reaction)
        reactionTimestamp = try c.decodeIfPresent(Date.self, forKey: .reactionTimestamp)
        chatMessage = try c.decodeIfPresent(String.self, forKey: .chatMessage)
        chatTimestamp = try c.decodeIfPresent(Date.self, forKey: .chatTimestamp)
        isTyping = try c.decodeIfPresent(Bool.self, forKey: .isTyping)
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
    let evolution: CreatureEvolution
    let xPosition: CGFloat
    let isLocal: Bool
    let displayName: String
    var sessionDuration: TimeInterval?
    var lastToolName: String?
    var facingRight: Bool = true
    var reaction: PeerReaction?
    var reactionActive: Bool = false
    var chatMessage: String?
    var isTyping: Bool = false
}
