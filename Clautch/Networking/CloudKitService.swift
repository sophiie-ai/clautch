import Foundation
import CloudKit
import os

/// Low-level CloudKit operations for rooms and presence.
final class CloudKitService: @unchecked Sendable {
    static let shared = CloudKitService()

    /// Container is lazily initialized to avoid crashing when CloudKit
    /// entitlements are not configured (e.g. local debug builds).
    private(set) lazy var container: CKContainer? = {
        // CKContainer(identifier:) will hard-crash (SIGTRAP) if the
        // iCloud container entitlement is missing. Guard against that
        // by checking the entitlement first.
        guard let entitlements = Bundle.main.infoDictionary,
              let _ = entitlements["com.apple.developer.icloud-container-identifiers"]
        else {
            // Also try checking the code-signing entitlements via SecTask
            if let task = SecTaskCreateFromSelf(nil),
               let value = SecTaskCopyValueForEntitlement(
                   task, "com.apple.developer.icloud-container-identifiers" as CFString, nil
               ),
               let ids = value as? [String],
               ids.contains("iCloud.com.clautch.app") {
                return CKContainer(identifier: "iCloud.com.clautch.app")
            }
            logger.warning("CloudKit container entitlement not found — room features disabled")
            return nil
        }
        return CKContainer(identifier: "iCloud.com.clautch.app")
    }()

    private var publicDB: CKDatabase? { container?.publicCloudDatabase }
    private let logger = Logger(subsystem: "com.clautch.app", category: "CloudKit")

    /// Whether CloudKit is configured and available.
    var isAvailable: Bool { container != nil }

    // Record type names
    static let roomType = "ClautchRoom"
    static let presenceType = "ClautchPresence"

    // MARK: - Room Operations

    /// Create a new room record.
    func createRoom(code: String, creatorPeerId: String) async throws -> CKRecord {
        guard let db = publicDB else { throw CloudKitUnavailableError() }
        let record = CKRecord(recordType: Self.roomType)
        record["roomCode"] = code
        record["creatorPeerId"] = creatorPeerId
        record["createdAt"] = Date() as NSDate

        let saved = try await db.save(record)
        logger.info("Room created: \(code)")
        return saved
    }

    /// Find a room by code.
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

    /// Delete a room record.
    func deleteRoom(recordID: CKRecord.ID) async throws {
        guard let db = publicDB else { throw CloudKitUnavailableError() }
        try await db.deleteRecord(withID: recordID)
        logger.info("Room deleted")
    }

    // MARK: - Presence Operations

    /// Write or update a presence record.
    /// Returns the saved record (use its recordID for future updates).
    func writePresence(
        existingRecordID: CKRecord.ID?,
        roomCode: String,
        state: PeerState
    ) async throws -> CKRecord {
        guard let db = publicDB else { throw CloudKitUnavailableError() }
        let record: CKRecord
        if let existingID = existingRecordID {
            // Fetch then update to avoid conflicts
            do {
                record = try await db.record(for: existingID)
            } catch {
                // Record may have been cleaned up; create a new one
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
        record["heartbeat"] = Date() as NSDate
        record["isActive"] = 1

        let saved = try await db.save(record)
        return saved
    }

    /// Fetch all presence records for a room.
    func fetchPresences(roomCode: String) async throws -> [(CKRecord.ID, PeerState)] {
        guard let db = publicDB else { throw CloudKitUnavailableError() }
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

    /// Delete a presence record.
    func deletePresence(recordID: CKRecord.ID) async throws {
        guard let db = publicDB else { throw CloudKitUnavailableError() }
        try await db.deleteRecord(withID: recordID)
        logger.info("Presence deleted")
    }

    /// Clean up stale presences (heartbeat older than 10 minutes).
    func cleanupStalePresences(roomCode: String) async throws {
        guard let db = publicDB else { throw CloudKitUnavailableError() }
        let cutoff = Date().addingTimeInterval(-600) as NSDate
        let predicate = NSPredicate(
            format: "roomCode == %@ AND heartbeat < %@", roomCode, cutoff
        )
        let query = CKQuery(recordType: Self.presenceType, predicate: predicate)
        let (results, _) = try await db.records(matching: query, resultsLimit: 50)

        for (id, _) in results {
            _ = try? await db.deleteRecord(withID: id)
        }
    }

    // MARK: - Account Check

    /// Check if CloudKit is available.
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

/// Thrown when CloudKit operations are attempted without a valid container.
struct CloudKitUnavailableError: LocalizedError {
    var errorDescription: String? { "CloudKit is not configured — add iCloud entitlement" }
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

        self.init(
            peerId: peerId,
            displayName: displayName,
            creatureType: CreatureType(rawValue: creatureRaw) ?? .ghost,
            task: CreatureTask(rawValue: taskRaw) ?? .idle,
            emotion: CreatureEmotion(rawValue: emotionRaw) ?? .neutral,
            colorPreset: CreatureColorPreset(rawValue: colorRaw) ?? .none,
            timestamp: heartbeat
        )
    }
}
