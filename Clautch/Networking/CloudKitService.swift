import Foundation
import CloudKit
import os

/// Low-level CloudKit operations for rooms and presence.
final class CloudKitService: @unchecked Sendable {
    static let shared = CloudKitService()

    /// Container is lazily initialized. Since the app runs without sandbox,
    /// CKContainer can be created directly. CloudKit availability is verified
    /// at runtime via accountStatus() — no entitlement check needed.
    private(set) lazy var container: CKContainer = {
        CKContainer(identifier: "iCloud.com.clautch.app")
    }()

    private var publicDB: CKDatabase { container.publicCloudDatabase }
    private let logger = Logger(subsystem: "com.clautch.app", category: "CloudKit")

    // Record type names
    static let roomType = "ClautchRoom"
    static let presenceType = "ClautchPresence"

    // MARK: - Room Operations

    /// Create a new room record with an invite token.
    func createRoom(code: String, creatorPeerId: String, inviteToken: String) async throws -> CKRecord {
        let record = CKRecord(recordType: Self.roomType)
        record["roomCode"] = code
        record["creatorPeerId"] = creatorPeerId
        record["inviteToken"] = inviteToken
        record["createdAt"] = Date() as NSDate

        let saved = try await publicDB.save(record)
        logger.info("Room created: \(code)")
        return saved
    }

    /// Find a room by code.
    func findRoom(code: String) async throws -> CKRecord? {
        let predicate = NSPredicate(format: "roomCode == %@", code)
        let query = CKQuery(recordType: Self.roomType, predicate: predicate)
        let (results, _) = try await publicDB.records(matching: query, resultsLimit: 1)

        for (_, result) in results {
            if let record = try? result.get() {
                return record
            }
        }
        return nil
    }

    /// Delete a room record.
    func deleteRoom(recordID: CKRecord.ID) async throws {
        try await publicDB.deleteRecord(withID: recordID)
        logger.info("Room deleted")
    }

    // MARK: - Presence Operations

    /// Write or update a presence record.
    func writePresence(
        existingRecordID: CKRecord.ID?,
        roomCode: String,
        state: PeerState
    ) async throws -> CKRecord {
        let record: CKRecord
        if let existingID = existingRecordID {
            do {
                record = try await publicDB.record(for: existingID)
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
        record["reaction"] = state.reaction?.rawValue ?? ""
        if let rt = state.reactionTimestamp {
            record["reactionTimestamp"] = rt as NSDate
        }
        record["chatMessage"] = state.chatMessage ?? ""
        if let ct = state.chatTimestamp {
            record["chatTimestamp"] = ct as NSDate
        }

        return try await publicDB.save(record)
    }

    /// Fetch all presence records for a room.
    func fetchPresences(roomCode: String) async throws -> [(CKRecord.ID, PeerState)] {
        let predicate = NSPredicate(format: "roomCode == %@", roomCode)
        let query = CKQuery(recordType: Self.presenceType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "heartbeat", ascending: false)]

        let (results, _) = try await publicDB.records(matching: query, resultsLimit: 20)

        var peers: [(CKRecord.ID, PeerState)] = []
        for (id, result) in results {
            guard let record = try? result.get() else { continue }
            guard let peer = PeerState(from: record) else { continue }
            peers.append((id, peer))
        }
        return peers
    }

    /// Delete a presence record.
    func deletePresence(recordID: CKRecord.ID) async throws {
        try await publicDB.deleteRecord(withID: recordID)
        logger.info("Presence deleted")
    }

    /// Clean up stale presences (heartbeat older than 10 minutes).
    func cleanupStalePresences(roomCode: String) async throws {
        let cutoff = Date().addingTimeInterval(-600) as NSDate
        let predicate = NSPredicate(
            format: "roomCode == %@ AND heartbeat < %@", roomCode, cutoff
        )
        let query = CKQuery(recordType: Self.presenceType, predicate: predicate)
        let (results, _) = try await publicDB.records(matching: query, resultsLimit: 50)

        for (id, _) in results {
            _ = try? await publicDB.deleteRecord(withID: id)
        }
    }

    // MARK: - Account Check

    /// Check if CloudKit is available.
    func checkAvailability() async -> Bool {
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            logger.error("CloudKit account check failed: \(error)")
            return false
        }
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

        let colorRaw = record["colorPreset"] as? String ?? "none"
        let accessoryRaw = record["accessory"] as? String ?? "none"
        let reactionRaw = record["reaction"] as? String ?? ""
        let chatMsg = record["chatMessage"] as? String ?? ""
        let chatTs = record["chatTimestamp"] as? Date
        let reactionTs = record["reactionTimestamp"] as? Date

        self.init(
            peerId: peerId,
            displayName: displayName,
            creatureType: CreatureType(rawValue: creatureRaw) ?? .ghost,
            task: CreatureTask(rawValue: taskRaw) ?? .idle,
            emotion: CreatureEmotion(rawValue: emotionRaw) ?? .neutral,
            colorPreset: CreatureColorPreset(rawValue: colorRaw) ?? .none,
            accessory: CreatureAccessory(rawValue: accessoryRaw) ?? .none,
            timestamp: heartbeat,
            reaction: reactionRaw.isEmpty ? nil : PeerReaction(rawValue: reactionRaw),
            reactionTimestamp: reactionTs,
            chatMessage: chatMsg.isEmpty ? nil : chatMsg,
            chatTimestamp: chatTs
        )
    }
}
