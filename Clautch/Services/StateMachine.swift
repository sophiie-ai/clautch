import Foundation
import os

/// Central event processor: receives hook events and updates session state.
/// Also broadcasts state changes to the room via RoomManager.
@Observable
@MainActor
final class StateMachine {
    static let shared = StateMachine()

    let sessionStore = SessionStore()
    private let logger = Logger(subsystem: "com.clautch.app", category: "StateMachine")
    private var cleanupTimer: Timer?

    private init() {
        // Wire up socket events → state transitions
        SocketServer.shared.onEvent = { [weak self] event in
            Task { @MainActor in
                self?.handleEvent(event)
            }
        }

        // Periodic cleanup of stale sessions
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sessionStore.cleanupStale()
            }
        }
    }

    private func handleEvent(_ event: HookEvent) {
        logger.debug("Event: \(event.eventType.rawValue) session=\(event.sessionId)")

        let session = sessionStore.getOrCreate(id: event.sessionId)
        session.applyEvent(event)

        if event.eventType == .sessionEnd {
            sessionStore.markInactive(id: event.sessionId)
        }

        // Notifications
        switch event.eventType {
        case .stop:
            NotificationService.shared.postSessionFinished(sessionId: event.sessionId)
        case .postToolUse:
            if let status = event.status, status == "error" || status == "failure" {
                NotificationService.shared.postToolError(sessionId: event.sessionId, toolName: event.toolName)
            }
        default:
            break
        }

        // Broadcast effective state to the room
        broadcastCurrentState()
    }

    /// Push the current effective session state to RoomManager for network broadcast.
    func broadcastCurrentState() {
        let effective = sessionStore.effectiveSession
        let task = effective?.state.task ?? .idle
        let emotion = effective?.state.emotion ?? .neutral
        RoomManager.shared.broadcastState(task: task, emotion: emotion)
    }
}
