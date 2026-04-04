import Foundation
import CryptoKit

/// Manages Ed25519 signing for peer state authentication.
/// Each device gets a persistent key pair stored in Keychain.
enum PeerSigner {
    private static let keychainKey = "com.clautch.signingKey"

    /// The device's Ed25519 signing key (generated once, persisted in Keychain).
    static let signingKey: Curve25519.Signing.PrivateKey = {
        if let data = KeychainHelper.readData(key: keychainKey),
           let key = try? Curve25519.Signing.PrivateKey(rawRepresentation: data) {
            return key
        }
        let key = Curve25519.Signing.PrivateKey()
        KeychainHelper.writeData(key: keychainKey, value: key.rawRepresentation)
        return key
    }()

    /// The public key as a Base64 string for broadcast.
    static var publicKeyString: String {
        signingKey.publicKey.rawRepresentation.base64EncodedString()
    }

    /// Sign a peer state payload. Signs peerId + task + emotion + displayName + chat + reaction + typing + timestamp.
    static func sign(
        peerId: String, task: String, emotion: String, timestamp: Date,
        displayName: String = "", chatMessage: String = "", reaction: String = "", isTyping: Bool = false
    ) -> String {
        let payload = signaturePayload(
            peerId: peerId, task: task, emotion: emotion, timestamp: timestamp,
            displayName: displayName, chatMessage: chatMessage, reaction: reaction, isTyping: isTyping
        )
        guard let sig = try? signingKey.signature(for: payload) else { return "" }
        return sig.withUnsafeBytes { Data($0).base64EncodedString() }
    }

    /// Verify a peer state signature against the claimed public key.
    static func verify(
        signature: String, publicKey: String,
        peerId: String, task: String, emotion: String, timestamp: Date,
        displayName: String = "", chatMessage: String = "", reaction: String = "", isTyping: Bool = false
    ) -> Bool {
        guard let sigData = Data(base64Encoded: signature),
              let pubData = Data(base64Encoded: publicKey),
              let pubKey = try? Curve25519.Signing.PublicKey(rawRepresentation: pubData) else {
            return false
        }
        let payload = signaturePayload(
            peerId: peerId, task: task, emotion: emotion, timestamp: timestamp,
            displayName: displayName, chatMessage: chatMessage, reaction: reaction, isTyping: isTyping
        )
        return pubKey.isValidSignature(sigData, for: payload)
    }

    private static func signaturePayload(
        peerId: String, task: String, emotion: String, timestamp: Date,
        displayName: String, chatMessage: String, reaction: String, isTyping: Bool
    ) -> Data {
        let ts = Int(timestamp.timeIntervalSinceReferenceDate)
        let message = "\(peerId):\(task):\(emotion):\(displayName):\(chatMessage):\(reaction):\(isTyping):\(ts)"
        return Data(message.utf8)
    }
}

// MARK: - KeychainHelper Data extensions

extension KeychainHelper {
    static func writeData(key: String, value: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = value
        SecItemAdd(add as CFDictionary, nil)
    }

    static func readData(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }
}
