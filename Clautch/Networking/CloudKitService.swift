import Foundation
import CloudKit
import os

/// Low-level CloudKit operations for rooms and presence.
final class CloudKitService: @unchecked Sendable {
    static let shared = CloudKitService()

    /// Container is lazily initialized. Returns nil if iCloud entitlements
    /// are not present in the code-signed binary (e.g. CI-built releases
    /// without a provisioning profile). Using CloudKit without entitlements
    /// causes an uncatchable SIGTRAP.
    private(set) lazy var container: CKContainer? = {
        // Check code-signing entitlements via SecTask
        if let task = SecTaskCreateFromSelf(nil),
           let value = SecTaskCopyValueForEntitlement(
               task, "com.apple.developer.icloud-container-identifiers" as CFString, nil
           ),
           let ids = value as? [String],
           ids.contains("iCloud.com.clautch.app") {
            return CKContainer(identifier: "iCloud.com.clautch.app")
        }
        // Check embedded provisioning profile (covers Developer ID builds)
        if let profileURL = Bundle.main.url(forResource: "embedded", withExtension: "provisionprofile"),
           let profileData = try? Data(contentsOf: profileURL),
           let profileString = String(data: profileData, encoding: .ascii),
           profileString.contains("iCloud.com.clautch.app") {
            return CKContainer(identifier: "iCloud.com.clautch.app")
        }
        logger.warning("CloudKit not available — iCloud entitlements not found in signed binary")
        return nil
    }()

    private var publicDB: CKDatabase? { container?.publicCloudDatabase }
    private let logger = Logger(subsystem: "com.clautch.app", category: "CloudKit")

    /// Whether CloudKit is available (entitlements present).
    var isAvailable: Bool { container != nil }

    // Record type names
    static let roomType = "ClautchRoom"
    static let presenceType = "ClautchPresence"

    // MARK: - Room Operations

    func createRoom(code: String, creatorPeerId: String, inviteToken: String) async throws -> CKRecord {
        guard let db = publicDB else { throw CloudKitUnavailableError() }
        let record = CKRecord(recordType: Self.roomType)
        record["roomCode"] = code
        record["creatorPeerId"] = creatorPeerId
        record["inviteToken"] = inviteToken
        record["createdAt"] = Date() as NSDate

        let saved = try await db.save(record)
        logger.info("Room created: \(code)")
        return saved
    }

    func findRoom(code: String) async throws -> CKRecord? {
        guard let db = publicDB else { throw CloudKitUnavailableError() }
        let predicate = NSPredicate(format: "roomCode == %@", code)
        let query = CKQuery(recordType: Self.roomType, predicate: predicate)
        let (results, _) = try await db.records(matching: query, resultsLimit: 1)

        for (_, result) in results {
            if let record = try? result.get() {
                return record
            }
        }
        return nil
    }

    func deleteRoom(recordID: CKRecord.ID) async throws {
        guard let db = publicDB else { throw CloudKitUnavailableError() }
        try await db.deleteRecord(withID: recordID)
        logger.info("Room deleted")
    }

    // MARK: - Presence Operations

    func writePresence(
        existingRecordID: CKRecord.ID?,
        roomCode: String,
        state: PeerState
    ) async throws -> CKRecord {
        guard let db = publicDB else { throw CloudKitUnavailableError() }
        return try await withRetry {
            let record: CKRecord
            if let existingID = existingRecordID {
                do {
                    record = try await db.record(for: existingID)
                } catch {
                    record = CKRecord(recordType: Self.presenceType)
                }
            } else {
                record = CKRecord(recordType: Self.presenceType)
            }

            record["roomCode"] = roomCode
            record["peerId"] = state.peerId
            record["displayName"] = state.displayName
            record["creatureType"] = state.creatureType.rawValue
            record["task"] = state.task.rawValue
            record["emotion"] = state.emotion.rawValue
            record["colorPreset"] = state.colorPreset.rawValue
            record["accessory"] = state.accessory.rawValue
            record["heartbeat"] = Date() as NSDate
            record["isActive"] = 1
            if let x = state.xPosition {
                record["xPosition"] = x as NSNumber
            }
            // Peer signing
            let sig = PeerSigner.sign(
                peerId: state.peerId, task: state.task.rawValue,
                emotion: state.emotion.rawValue, timestamp: Date()
            )
            record["publicKey"] = PeerSigner.publicKeyString
            record["signature"] = sig
            record["reaction"] = state.reaction?.rawValue ?? ""
            if let rt = state.reactionTimestamp {
                record["reactionTimestamp"] = rt as NSDate
            }
            record["chatMessage"] = state.chatMessage ?? ""
            if let ct = state.chatTimestamp {
                record["chatTimestamp"] = ct as NSDate
            }

            return try await db.save(record)
        }
    }

    func fetchPresences(roomCode: String) async throws -> [(CKRecord.ID, PeerState)] {
        guard let db = publicDB else { throw CloudKitUnavailableError() }
        return try await withRetry {
            let predicate = NSPredicate(format: "roomCode == %@", roomCode)
            let query = CKQuery(recordType: Self.presenceType, predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "heartbeat", ascending: false)]

            let (results, _) = try await db.records(matching: query, resultsLimit: 20)

            var peers: [(CKRecord.ID, PeerState)] = []
            for (id, result) in results {
                guard let record = try? result.get() else { continue }
                guard let peer = PeerState(from: record) else { continue }
                peers.append((id, peer))
            }
            return peers
        }
    }

    func deletePresence(recordID: CKRecord.ID) async throws {
        guard let db = publicDB else { throw CloudKitUnavailableError() }
        try await db.deleteRecord(withID: recordID)
        logger.info("Presence deleted")
    }

    func cleanupStalePresences(roomCode: String) async throws {
        guard let db = publicDB else { throw CloudKitUnavailableError() }
        try await withRetry {
            let cutoff = Date().addingTimeInterval(-300) as NSDate
            let predicate = NSPredicate(
                format: "roomCode == %@ AND heartbeat < %@", roomCode, cutoff
            )
            let query = CKQuery(recordType: Self.presenceType, predicate: predicate)
            let (results, _) = try await db.records(matching: query, resultsLimit: 50)

            let idsToDelete = results.map(\.0)
            if !idsToDelete.isEmpty {
                let op = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: idsToDelete)
                op.qualityOfService = .utility
                try await db.add(op)
            }
        }
    }

    // MARK: - Room Expiry

    /// Check if a room has any active presences. If none are active for > 2 hours, delete it.
    func expireRoomIfStale(roomCode: String) async throws -> Bool {
        guard let db = publicDB else { throw CloudKitUnavailableError() }
        return try await withRetry {
            // Check for any active presence in this room
            let activeCutoff = Date().addingTimeInterval(-300) as NSDate // 5 min
            let predicate = NSPredicate(
                format: "roomCode == %@ AND heartbeat > %@", roomCode, activeCutoff
            )
            let query = CKQuery(recordType: Self.presenceType, predicate: predicate)
            let (results, _) = try await db.records(matching: query, resultsLimit: 1)

            if results.isEmpty {
                // No active peers — check if the room itself is old enough to expire
                if let roomRecord = try await self.findRoom(code: roomCode),
                   let createdAt = roomRecord["createdAt"] as? Date,
                   Date().timeIntervalSince(createdAt) > 7200 { // 2 hours
                    try await db.deleteRecord(withID: roomRecord.recordID)
                    // Also cleanup all stale presences for this room
                    try await self.cleanupStalePresences(roomCode: roomCode)
                    self.logger.info("Expired stale room: \(roomCode)")
                    return true
                }
            }
            return false
        }
    }

    // MARK: - Retry Logic

    /// Retry transient CloudKit errors with exponential backoff.
    private func withRetry<T>(
        maxAttempts: Int = 3,
        _ operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        for attempt in 0..<maxAttempts {
            do {
                return try await operation()
            } catch let error as CKError where Self.isTransient(error) {
                lastError = error
                if attempt < maxAttempts - 1 {
                    let delay = pow(2.0, Double(attempt)) // 1s, 2s, 4s
                    try? await Task.sleep(for: .seconds(delay))
                }
            }
        }
        throw lastError!
    }

    private static func isTransient(_ error: CKError) -> Bool {
        switch error.code {
        case .networkUnavailable, .networkFailure,
             .serviceUnavailable, .serverResponseLost,
             .requestRateLimited, .zoneBusy:
            return true
        default:
            return false
        }
    }

    // MARK: - Subscriptions

    private static let presenceSubscriptionID = "presence-changes"

    /// Subscribe to presence changes for a room. CloudKit sends silent pushes on changes.
    func subscribeToPresence(roomCode: String) async throws {
        guard let db = publicDB else { throw CloudKitUnavailableError() }

        // Remove existing subscription first (idempotent)
        try? await db.deleteSubscription(withID: Self.presenceSubscriptionID)

        let predicate = NSPredicate(format: "roomCode == %@", roomCode)
        let subscription = CKQuerySubscription(
            recordType: Self.presenceType,
            predicate: predicate,
            subscriptionID: Self.presenceSubscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )

        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true  // silent push
        subscription.notificationInfo = info

        try await db.save(subscription)
        logger.info("Subscribed to presence changes for room \(roomCode)")
    }

    /// Remove the presence subscription.
    func unsubscribeFromPresence() async {
        guard let db = publicDB else { return }
        try? await db.deleteSubscription(withID: Self.presenceSubscriptionID)
        logger.info("Unsubscribed from presence changes")
    }

    // MARK: - Account Check

    func checkAvailability() async -> Bool {
        guard let container else { return false }
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            logger.error("CloudKit account check failed: \(error)")
            return false
        }
    }
}

/// Thrown when CloudKit operations are attempted without iCloud entitlements.
struct CloudKitUnavailableError: LocalizedError {
    var errorDescription: String? {
        "Room features require a locally-built version. CI-built releases don't include iCloud entitlements yet."
    }
}

// MARK: - PeerState from CKRecord

extension PeerState {
    init?(from record: CKRecord) {
        guard let peerId = record["peerId"] as? String,
              let displayName = record["displayName"] as? String,
              let creatureRaw = record["creatureType"] as? String,
              let taskRaw = record["task"] as? String,
              let emotionRaw = record["emotion"] as? String,
              let heartbeat = record["heartbeat"] as? Date
        else { return nil }

        // Reject oversized or invalid fields
        guard peerId.count <= 64,
              displayName.count <= 100,
              creatureRaw.count <= 32,
              taskRaw.count <= 32,
              emotionRaw.count <= 32,
              CreatureType(rawValue: creatureRaw) != nil,
              CreatureTask(rawValue: taskRaw) != nil,
              CreatureEmotion(rawValue: emotionRaw) != nil
        else { return nil }

        let colorRaw = record["colorPreset"] as? String ?? "none"
        let accessoryRaw = record["accessory"] as? String ?? "none"
        let xPos = record["xPosition"] as? Double
        let pubKey = record["publicKey"] as? String
        let sig = record["signature"] as? String
        let reactionRaw = record["reaction"] as? String ?? ""
        let chatMsg = record["chatMessage"] as? String ?? ""
        let chatTs = record["chatTimestamp"] as? Date
        let reactionTs = record["reactionTimestamp"] as? Date

        // Verify signature if present — reject peers with invalid signatures
        if let pubKey, let sig, !pubKey.isEmpty, !sig.isEmpty {
            let valid = PeerSigner.verify(
                signature: sig, publicKey: pubKey,
                peerId: peerId, task: taskRaw, emotion: emotionRaw, timestamp: heartbeat
            )
            if !valid { return nil }
        }

        self.init(
            peerId: peerId,
            displayName: String(displayName.prefix(50)),
            creatureType: CreatureType(rawValue: creatureRaw)!,
            task: CreatureTask(rawValue: taskRaw)!,
            emotion: CreatureEmotion(rawValue: emotionRaw)!,
            colorPreset: CreatureColorPreset(rawValue: colorRaw) ?? .none,
            accessory: CreatureAccessory(rawValue: accessoryRaw) ?? .none,
            timestamp: heartbeat,
            xPosition: xPos.map { CGFloat(min(max($0, 0), 1)) },
            publicKey: pubKey,
            signature: sig,
            reaction: reactionRaw.isEmpty ? nil : PeerReaction(rawValue: reactionRaw),
            reactionTimestamp: reactionTs,
            chatMessage: chatMsg.isEmpty ? nil : String(chatMsg.prefix(50)),
            chatTimestamp: chatTs
        )
    }
}
