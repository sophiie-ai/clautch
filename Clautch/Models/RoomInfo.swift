import Foundation
import CloudKit

/// Metadata about the current room.
struct RoomInfo: Codable, Sendable {
    let roomCode: String
    let inviteToken: String?
    let createdAt: Date
    let creatorPeerId: String
    var recordID: String?   // CKRecord.ID.recordName for updates/deletion

    /// The shareable invite string: CODE-TOKEN (or just CODE for legacy rooms).
    var shareableCode: String {
        if let token = inviteToken {
            return "\(roomCode)-\(token)"
        }
        return roomCode
    }

    /// Parse a shareable code into (roomCode, inviteToken?).
    /// Accepts "ABCDEF" (legacy) or "ABCDEF-xYz123..." (with token).
    static func parse(shareableCode: String) -> (code: String, token: String?) {
        let trimmed = shareableCode.trimmingCharacters(in: .whitespaces)
        guard let dashIndex = trimmed.firstIndex(of: "-"),
              trimmed.distance(from: trimmed.startIndex, to: dashIndex) == 6 else {
            // No dash or dash not at position 6 — treat as bare code
            return (String(trimmed.prefix(6)).uppercased(), nil)
        }
        let code = String(trimmed[trimmed.startIndex..<dashIndex]).uppercased()
        let token = String(trimmed[trimmed.index(after: dashIndex)...])
        return (code, token.isEmpty ? nil : token)
    }

    /// Generate a 6-character room code (alphanumeric, no ambiguous chars).
    static func generateCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in chars.randomElement()! })
    }

    /// Generate a cryptographic invite token (128 bits, Base62 encoded).
    static func generateInviteToken() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
        return String(bytes.map { chars[Int($0) % chars.count] })
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
    private static let roomTokenKey = "com.clautch.lastRoomToken"

    /// The last shareable code (CODE-TOKEN or bare CODE) for auto-rejoin.
    var lastRoomCode: String? {
        get { string(forKey: Self.roomCodeKey) }
        set { set(newValue, forKey: Self.roomCodeKey) }
    }

    var lastRoomToken: String? {
        get { string(forKey: Self.roomTokenKey) }
        set { set(newValue, forKey: Self.roomTokenKey) }
    }
}
