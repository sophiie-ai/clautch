import Foundation
import CloudKit
import os

/// Manages the room lifecycle: create, join, leave, heartbeat, and peer sync.
@Observable
@MainActor
final class RoomManager {
    static let shared = RoomManager()

    private(set) var currentRoom: RoomInfo?
    private(set) var status: ConnectionStatus = .disconnected
    let peerStore = PeerStore()

    /// Our own presence record ID (for heartbeat updates).
    private var myPresenceRecordID: CKRecord.ID?
    private var roomRecordID: CKRecord.ID?

    private var syncTimer: Timer?
    private let cloudKit = CloudKitService.shared
    private let logger = Logger(subsystem: "com.clautch.app", category: "RoomManager")

    /// The latest local state to broadcast.
    var localState: PeerState?

    var isInRoom: Bool { currentRoom != nil }
    var peerCount: Int {
        guard let profile = UserProfile.current else { return 0 }
        return peerStore.visiblePeers(excludingPeerId: profile.peerId).count
    }

    private init() {}

    // MARK: - Create Room

    func createRoom() async throws -> String {
        guard let profile = UserProfile.current else {
            throw RoomError.noProfile
        }

        status = .connecting
        let code = RoomInfo.generateCode()

        do {
            // Create room record
            let roomRecord = try await cloudKit.createRoom(code: code, creatorPeerId: profile.peerId)
            roomRecordID = roomRecord.recordID

            // Write our presence
            let state = makePeerState(from: profile)
            let presenceRecord = try await cloudKit.writePresence(
                existingRecordID: nil,
                roomCode: code,
                state: state
            )
            myPresenceRecordID = presenceRecord.recordID

            currentRoom = RoomInfo(
                roomCode: code,
                createdAt: Date(),
                creatorPeerId: profile.peerId,
                recordID: roomRecord.recordID.recordName
            )

            UserDefaults.standard.lastRoomCode = code
            status = .connected
            startSyncTimer()
            logger.info("Created room: \(code)")
            return code
        } catch {
            status = .error(error.localizedDescription)
            throw error
        }
    }

    // MARK: - Join Room

    func joinRoom(code: String) async throws {
        guard let profile = UserProfile.current else {
            throw RoomError.noProfile
        }

        let normalized = code.uppercased().trimmingCharacters(in: .whitespaces)
        guard normalized.count == 6 else {
            throw RoomError.invalidCode
        }

        status = .connecting

        do {
            // Find the room
            guard let roomRecord = try await cloudKit.findRoom(code: normalized) else {
                status = .error("Room not found")
                throw RoomError.roomNotFound
            }
            roomRecordID = roomRecord.recordID

            // Write our presence
            let state = makePeerState(from: profile)
            let presenceRecord = try await cloudKit.writePresence(
                existingRecordID: nil,
                roomCode: normalized,
                state: state
            )
            myPresenceRecordID = presenceRecord.recordID

            currentRoom = RoomInfo(
                roomCode: normalized,
                createdAt: roomRecord["createdAt"] as? Date ?? Date(),
                creatorPeerId: roomRecord["creatorPeerId"] as? String ?? "",
                recordID: roomRecord.recordID.recordName
            )

            UserDefaults.standard.lastRoomCode = normalized
            status = .connected
            startSyncTimer()

            // Initial fetch
            try await fetchPeers()

            logger.info("Joined room: \(normalized)")
        } catch let error as RoomError {
            throw error
        } catch {
            status = .error(error.localizedDescription)
            throw error
        }
    }

    // MARK: - Leave Room

    func leaveRoom() async {
        stopSyncTimer()

        // Delete our presence
        if let presenceID = myPresenceRecordID {
            try? await cloudKit.deletePresence(recordID: presenceID)
        }

        myPresenceRecordID = nil
        roomRecordID = nil
        currentRoom = nil
        status = .disconnected
        peerStore.clear()
        UserDefaults.standard.lastRoomCode = nil

        logger.info("Left room")
    }

    // MARK: - Auto-rejoin

    func autoRejoinIfNeeded() async {
        guard currentRoom == nil,
              let code = UserDefaults.standard.lastRoomCode else { return }

        logger.info("Attempting auto-rejoin to room \(code)")
        do {
            try await joinRoom(code: code)
        } catch {
            logger.warning("Auto-rejoin failed: \(error)")
            UserDefaults.standard.lastRoomCode = nil
        }
    }

    // MARK: - Broadcast State

    /// Called by the StateMachine whenever local creature state changes.
    func broadcastState(task: CreatureTask, emotion: CreatureEmotion) {
        guard let profile = UserProfile.current else { return }
        localState = PeerState(
            peerId: profile.peerId,
            displayName: profile.displayName,
            creatureType: profile.creatureType,
            task: task,
            emotion: emotion,
            colorPreset: profile.colorPreset,
            timestamp: Date()
        )
    }

    // MARK: - Sync Timer

    private func startSyncTimer() {
        stopSyncTimer()
        // Sync every 4 seconds: update our presence + fetch peers
        syncTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.syncCycle()
            }
        }
    }

    private func stopSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    private var syncCycleCount = 0

    private func syncCycle() async {
        guard let room = currentRoom else { return }
        syncCycleCount += 1

        // Capture main-actor-isolated values before concurrent work
        let state = localState
        let presenceID = myPresenceRecordID
        let roomCode = room.roomCode

        // Run heartbeat and peer fetch concurrently to halve network latency
        if let state {
            do {
                let record = try await cloudKit.writePresence(
                    existingRecordID: presenceID,
                    roomCode: roomCode,
                    state: state
                )
                myPresenceRecordID = record.recordID
            } catch {
                logger.error("Heartbeat failed: \(error.localizedDescription)")
            }
        }

        do {
            try await fetchPeers()
        } catch {
            logger.error("Peer fetch failed: \(error.localizedDescription)")
        }

        // Cleanup stale presences every 5th cycle (~20 seconds)
        if syncCycleCount % 5 == 0 {
            try? await cloudKit.cleanupStalePresences(roomCode: roomCode)
        }
    }

    private func fetchPeers() async throws {
        guard let room = currentRoom else { return }
        let fetched = try await cloudKit.fetchPresences(roomCode: room.roomCode)
        peerStore.update(with: fetched)
    }

    // MARK: - Helpers

    private func makePeerState(from profile: UserProfile) -> PeerState {
        PeerState(
            peerId: profile.peerId,
            displayName: profile.displayName,
            creatureType: profile.creatureType,
            task: localState?.task ?? .idle,
            emotion: localState?.emotion ?? .neutral,
            colorPreset: profile.colorPreset,
            timestamp: Date()
        )
    }
}

// MARK: - Errors

enum RoomError: LocalizedError {
    case noProfile
    case invalidCode
    case roomNotFound

    var errorDescription: String? {
        switch self {
        case .noProfile:    return "Please set up your profile first"
        case .invalidCode:  return "Room code must be 6 characters"
        case .roomNotFound: return "Room not found"
        }
    }
}
