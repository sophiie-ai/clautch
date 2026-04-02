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

    /// Track last-broadcast state to avoid redundant CloudKit writes.
    private var lastBroadcastState: PeerState?
    private var lastHeartbeatDate: Date = .distantPast

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
            ensureLocalState()
            startSyncTimer()
            logger.info("Created room: \(code)")
            return code
        } catch {
            let friendly = RoomError.from(error)
            status = .error(friendly.localizedDescription ?? error.localizedDescription)
            throw friendly
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
        guard normalized.count == 6 || normalized.count == 8 else {
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
            let friendly = RoomError.from(error)
            status = .error(friendly.localizedDescription ?? error.localizedDescription)
            throw friendly
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
        lastBroadcastState = nil
        lastHeartbeatDate = .distantPast
        consecutiveFailures = 0
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

    /// Ensure localState exists, creating from profile if needed.
    @discardableResult
    private func ensureLocalState() -> PeerState? {
        if localState != nil { return localState }
        guard let profile = UserProfile.current else { return nil }
        localState = makePeerState(from: profile)
        return localState
    }

    func broadcastState(task: CreatureTask, emotion: CreatureEmotion) {
        guard let profile = UserProfile.current else { return }
        // Preserve active reaction, chat, and position when updating state
        let existingReaction = localState?.reaction
        let existingReactionTs = localState?.reactionTimestamp
        let existingChat = localState?.chatMessage
        let existingChatTs = localState?.chatTimestamp
        let existingPos = localState?.xPosition
        localState = PeerState(
            peerId: profile.peerId,
            displayName: profile.displayName,
            creatureType: profile.creatureType,
            task: task,
            emotion: emotion,
            colorPreset: profile.colorPreset,
            accessory: profile.accessory,
            timestamp: Date(),
            xPosition: existingPos,
            reaction: existingReaction,
            reactionTimestamp: existingReactionTs,
            chatMessage: existingChat,
            chatTimestamp: existingChatTs
        )
    }

    /// Update the local creature's position for network broadcast.
    func updatePosition(_ x: CGFloat) {
        localState?.xPosition = x
    }

    /// Send a chat message — broadcast on next sync, auto-clear after 8s.
    func sendChat(_ message: String) {
        guard var state = ensureLocalState() else { return }
        let trimmed = String(message.prefix(50))
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
            xPosition: state.xPosition,
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
        guard var state = ensureLocalState() else { return }
        state = PeerState(
            peerId: state.peerId,
            displayName: state.displayName,
            creatureType: state.creatureType,
            task: state.task,
            emotion: state.emotion,
            colorPreset: state.colorPreset,
            accessory: state.accessory,
            timestamp: Date(),
            xPosition: state.xPosition,
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
    private var consecutiveFailures = 0

    private func syncCycle() async {
        guard let room = currentRoom else { return }
        syncCycleCount += 1

        let state = localState
        let presenceID = myPresenceRecordID
        let roomCode = room.roomCode

        // Only write if state changed or heartbeat is older than 30s
        let stateChanged = state.map { s in
            lastBroadcastState.map { !s.broadcastEquals($0) } ?? true
        } ?? false
        let heartbeatStale = Date().timeIntervalSince(lastHeartbeatDate) > 30
        let shouldWrite = stateChanged || heartbeatStale

        // Run heartbeat (if needed) and peer fetch concurrently
        async let heartbeatRecord: CKRecord? = shouldWrite
            ? writeHeartbeat(state: state, presenceID: presenceID, roomCode: roomCode)
            : nil
        async let fetchedPeers: [(CKRecord.ID, PeerState)] = fetchPresences(roomCode: roomCode)

        let record = await heartbeatRecord
        let peers = await fetchedPeers

        // Track connectivity: if both write and fetch returned nothing, it's a failure
        let fetchFailed = peers.isEmpty && shouldWrite && record == nil
        if fetchFailed {
            consecutiveFailures += 1
            if consecutiveFailures >= 3 && status == .connected {
                status = .reconnecting
                logger.warning("CloudKit unreachable, reconnecting…")
            }
        } else {
            if consecutiveFailures > 0 && status == .reconnecting {
                status = .connected
                logger.info("CloudKit connection restored")
            }
            consecutiveFailures = 0
        }

        if let record {
            myPresenceRecordID = record.recordID
            lastBroadcastState = state
            lastHeartbeatDate = Date()
        }
        if !peers.isEmpty {
            peerStore.update(with: peers)
        }

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
    case cloudKitUnavailable
    case networkError
    case notSignedIn
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .noProfile:         return "Please set up your profile first"
        case .invalidCode:       return "Invalid room code"
        case .roomNotFound:      return "Room not found"
        case .invalidToken:      return "Invalid invite link"
        case .cloudKitUnavailable: return "iCloud is not available. Sign in to iCloud in System Settings to use rooms."
        case .networkError:      return "Network error. Check your internet connection and try again."
        case .notSignedIn:       return "Please sign in to iCloud in System Settings to use rooms."
        case .serverError(let detail): return "Server error: \(detail)"
        }
    }

    /// Map a raw error to a user-friendly RoomError.
    static func from(_ error: Error) -> RoomError {
        if let roomError = error as? RoomError { return roomError }
        if let ckError = error as? CKError {
            switch ckError.code {
            case .networkUnavailable, .networkFailure:
                return .networkError
            case .notAuthenticated:
                return .notSignedIn
            case .permissionFailure:
                return .serverError("Permission denied. Try signing out and back into iCloud.")
            case .quotaExceeded:
                return .serverError("iCloud storage is full.")
            case .serverResponseLost, .serviceUnavailable:
                return .networkError
            default:
                return .serverError(ckError.localizedDescription)
            }
        }
        if let unavailable = error as? CloudKitUnavailableError {
            return .cloudKitUnavailable
        }
        return .serverError(error.localizedDescription)
    }
}
