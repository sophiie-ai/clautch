import Foundation
import CloudKit

/// Metadata about the current room.
struct RoomInfo: Codable, Sendable {
    let roomCode: String
    let createdAt: Date
    let creatorPeerId: String
    var recordID: String?   // CKRecord.ID.recordName for updates/deletion

    /// Generate a 6-character room code (alphanumeric, no ambiguous chars).
    static func generateCode() -> String {
        // Exclude 0/O, 1/l/I to avoid confusion
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}

// MARK: - Connection Status

enum ConnectionStatus: Sendable {
    case disconnected
    case connecting
    case connected
    case error(String)

    var label: String {
        switch self {
        case .disconnected: return "Not in a room"
        case .connecting:   return "Connecting…"
        case .connected:    return "Connected"
        case .error(let msg): return "Error: \(msg)"
        }
    }
}

// MARK: - Persisted room for auto-rejoin

extension UserDefaults {
    private static let roomCodeKey = "com.clautch.lastRoomCode"

    var lastRoomCode: String? {
        get { string(forKey: Self.roomCodeKey) }
        set { set(newValue, forKey: Self.roomCodeKey) }
    }
}
