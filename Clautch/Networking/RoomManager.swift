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
        let token = RoomInfo.generateInviteToken()

        do {
            let roomRecord = try await cloudKit.createRoom(
                code: code, creatorPeerId: profile.peerId, inviteToken: token
            )
            roomRecordID = roomRecord.recordID

            let state = makePeerState(from: profile)
            let presenceRecord = try await cloudKit.writePresence(
                existingRecordID: nil,
                roomCode: code,
                state: state
            )
            myPresenceRecordID = presenceRecord.recordID

            currentRoom = RoomInfo(
                roomCode: code,
                inviteToken: token,
                createdAt: Date(),
                creatorPeerId: profile.peerId,
                recordID: roomRecord.recordID.recordName
            )

            UserDefaults.standard.lastRoomCode = code
            UserDefaults.standard.lastRoomToken = token
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

    /// Join a room using a shareable code (CODE-TOKEN or bare CODE for legacy rooms).
    func joinRoom(shareableCode: String) async throws {
        let (code, token) = RoomInfo.parse(shareableCode: shareableCode)
        try await joinRoom(code: code, inviteToken: token)
    }

    func joinRoom(code: String, inviteToken: String? = nil) async throws {
        guard let profile = UserProfile.current else {
            throw RoomError.noProfile
        }

        let normalized = code.uppercased().trimmingCharacters(in: .whitespaces)
        guard normalized.count == 6 else {
            throw RoomError.invalidCode
        }

        status = .connecting

        do {
            guard let roomRecord = try await cloudKit.findRoom(code: normalized) else {
                status = .error("Room not found")
                throw RoomError.roomNotFound
            }

            // Validate invite token if the room has one
            let serverToken = roomRecord["inviteToken"] as? String
            if let serverToken, !serverToken.isEmpty {
                guard let inviteToken, inviteToken == serverToken else {
                    status = .error("Invalid invite link")
                    throw RoomError.invalidToken
                }
            }

            roomRecordID = roomRecord.recordID

            let state = makePeerState(from: profile)
            let presenceRecord = try await cloudKit.writePresence(
                existingRecordID: nil,
                roomCode: normalized,
                state: state
            )
            myPresenceRecordID = presenceRecord.recordID

            currentRoom = RoomInfo(
                roomCode: normalized,
                inviteToken: serverToken,
                createdAt: roomRecord["createdAt"] as? Date ?? Date(),
                creatorPeerId: roomRecord["creatorPeerId"] as? String ?? "",
                recordID: roomRecord.recordID.recordName
            )

            UserDefaults.standard.lastRoomCode = normalized
            UserDefaults.standard.lastRoomToken = serverToken
            status = .connected
            startSyncTimer()

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

        if let presenceID = myPresenceRecordID {
            try? await cloudKit.deletePresence(recordID: presenceID)
        }

        myPresenceRecordID = nil
        roomRecordID = nil
        currentRoom = nil
        status = .disconnected
        peerStore.clear()
        UserDefaults.standard.lastRoomCode = nil
        UserDefaults.standard.lastRoomToken = nil

        logger.info("Left room")
    }

    // MARK: - Auto-rejoin

    func autoRejoinIfNeeded() async {
        guard currentRoom == nil,
              let code = UserDefaults.standard.lastRoomCode else { return }

        let token = UserDefaults.standard.lastRoomToken
        logger.info("Attempting auto-rejoin to room \(code)")
        do {
            try await joinRoom(code: code, inviteToken: token)
        } catch {
            logger.warning("Auto-rejoin failed: \(error)")
            UserDefaults.standard.lastRoomCode = nil
            UserDefaults.standard.lastRoomToken = nil
        }
    }

    // MARK: - Broadcast State

    func broadcastState(task: CreatureTask, emotion: CreatureEmotion) {
        guard let profile = UserProfile.current else { return }
        // Preserve active reaction and chat when updating state
        let existingReaction = localState?.reaction
        let existingReactionTs = localState?.reactionTimestamp
        let existingChat = localState?.chatMessage
        let existingChatTs = localState?.chatTimestamp
        localState = PeerState(
            peerId: profile.peerId,
            displayName: profile.displayName,
            creatureType: profile.creatureType,
            task: task,
            emotion: emotion,
            colorPreset: profile.colorPreset,
            accessory: profile.accessory,
            timestamp: Date(),
            reaction: existingReaction,
            reactionTimestamp: existingReactionTs,
            chatMessage: existingChat,
            chatTimestamp: existingChatTs
        )
    }

    /// Send a chat message — broadcast on next sync, auto-clear after 8s.
    func sendChat(_ message: String) {
        guard var state = localState else { return }
        let trimmed = String(message.prefix(60))
        guard !trimmed.isEmpty else { return }
        state = PeerState(
            peerId: state.peerId,
            displayName: state.displayName,
            creatureType: state.creatureType,
            task: state.task,
            emotion: state.emotion,
            colorPreset: state.colorPreset,
            accessory: state.accessory,
            timestamp: Date(),
            reaction: state.reaction,
            reactionTimestamp: state.reactionTimestamp,
            chatMessage: trimmed,
            chatTimestamp: Date()
        )
        localState = state

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(8))
            if localState?.chatMessage == trimmed {
                localState?.chatMessage = nil
                localState?.chatTimestamp = nil
            }
        }
    }

    /// Send a reaction — it will be broadcast on the next sync cycle and auto-clear after 4s.
    func sendReaction(_ reaction: PeerReaction) {
        guard var state = localState else { return }
        state = PeerState(
            peerId: state.peerId,
            displayName: state.displayName,
            creatureType: state.creatureType,
            task: state.task,
            emotion: state.emotion,
            colorPreset: state.colorPreset,
            accessory: state.accessory,
            timestamp: Date(),
            reaction: reaction,
            reactionTimestamp: Date(),
            chatMessage: state.chatMessage,
            chatTimestamp: state.chatTimestamp
        )
        localState = state

        // Auto-clear after 4 seconds
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            if localState?.reaction == reaction {
                localState?.reaction = nil
                localState?.reactionTimestamp = nil
            }
        }
    }

    // MARK: - Sync Timer

    private func startSyncTimer() {
        stopSyncTimer()
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

        let state = localState
        let presenceID = myPresenceRecordID
        let roomCode = room.roomCode

        // Run heartbeat and peer fetch concurrently via nonisolated helpers
        async let heartbeatRecord: CKRecord? = writeHeartbeat(
            state: state, presenceID: presenceID, roomCode: roomCode
        )
        async let fetchedPeers: [(CKRecord.ID, PeerState)] = fetchPresences(roomCode: roomCode)

        let record = await heartbeatRecord
        let peers = await fetchedPeers

        if let record { myPresenceRecordID = record.recordID }
        peerStore.update(with: peers)

        if syncCycleCount % 5 == 0 {
            try? await cloudKit.cleanupStalePresences(roomCode: roomCode)
        }
    }

    /// nonisolated so async let can run this off the main actor concurrently.
    private nonisolated func writeHeartbeat(
        state: PeerState?, presenceID: CKRecord.ID?, roomCode: String
    ) async -> CKRecord? {
        guard let state else { return nil }
        return try? await cloudKit.writePresence(
            existingRecordID: presenceID, roomCode: roomCode, state: state
        )
    }

    /// nonisolated so async let can run this off the main actor concurrently.
    private nonisolated func fetchPresences(roomCode: String) async -> [(CKRecord.ID, PeerState)] {
        (try? await cloudKit.fetchPresences(roomCode: roomCode)) ?? []
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
            accessory: profile.accessory,
            timestamp: Date()
        )
    }
}

// MARK: - Errors

enum RoomError: LocalizedError {
    case noProfile
    case invalidCode
    case roomNotFound
    case invalidToken

    var errorDescription: String? {
        switch self {
        case .noProfile:    return "Please set up your profile first"
        case .invalidCode:  return "Room code must be 6 characters"
        case .roomNotFound: return "Room not found"
        case .invalidToken: return "Invalid invite link"
        }
    }
}
