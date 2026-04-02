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
    /// Accepts "ABCDEFGH" (bare) or "ABCDEFGH-xYz123..." (with token).
    /// Also accepts legacy 6-char codes.
    static func parse(shareableCode: String) -> (code: String, token: String?) {
        let trimmed = shareableCode.trimmingCharacters(in: .whitespaces)
        if let dashIndex = trimmed.firstIndex(of: "-") {
            let pos = trimmed.distance(from: trimmed.startIndex, to: dashIndex)
            if pos == 8 || pos == 6 { // 8-char (current) or 6-char (legacy)
                let code = String(trimmed[trimmed.startIndex..<dashIndex]).uppercased()
                let token = String(trimmed[trimmed.index(after: dashIndex)...])
                return (code, token.isEmpty ? nil : token)
            }
        }
        // Bare code (no token)
        let codeLen = min(trimmed.count, 8)
        return (String(trimmed.prefix(codeLen)).uppercased(), nil)
    }

    /// Generate an 8-character room code (alphanumeric, no ambiguous chars).
    /// 32^8 ≈ 1.1 trillion possibilities.
    static func generateCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<8).map { _ in chars.randomElement()! })
    }

    /// Generate a cryptographic invite token (Base62, rejection-sampled for uniform distribution).
    static func generateInviteToken() -> String {
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
        let limit = UInt8(256 / chars.count * chars.count) // 248 — largest multiple of 62 ≤ 256
        var result = [Character]()
        result.reserveCapacity(22)
        while result.count < 22 {
            var byte: UInt8 = 0
            _ = SecRandomCopyBytes(kSecRandomDefault, 1, &byte)
            if byte < limit {
                result.append(chars[Int(byte) % chars.count])
            }
        }
        return String(result)
    }
}

// MARK: - Connection Status

enum ConnectionStatus: Sendable, Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case error(String)

    var label: String {
        switch self {
        case .disconnected:  return "Not in a room"
        case .connecting:    return "Connecting…"
        case .connected:     return "Connected"
        case .reconnecting:  return "Reconnecting…"
        case .error(let msg): return "Error: \(msg)"
        }
    }
}

// MARK: - Persisted room for auto-rejoin

extension UserDefaults {
    private static let roomCodeKey = "com.clautch.lastRoomCode"

    /// The last room code for auto-rejoin (not sensitive).
    var lastRoomCode: String? {
        get { string(forKey: Self.roomCodeKey) }
        set { set(newValue, forKey: Self.roomCodeKey) }
    }

    /// Room invite token stored in Keychain.
    var lastRoomToken: String? {
        get { KeychainHelper.read(key: "com.clautch.lastRoomToken") }
        set {
            if let value = newValue {
                KeychainHelper.write(key: "com.clautch.lastRoomToken", value: value)
            } else {
                KeychainHelper.delete(key: "com.clautch.lastRoomToken")
            }
        }
    }
}

// MARK: - Keychain Helper

enum KeychainHelper {
    static func write(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        SecItemAdd(add as CFDictionary, nil)
    }

    static func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
