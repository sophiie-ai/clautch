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
        sessionStore.invalidateCache()

        if event.eventType == .sessionEnd {
            sessionStore.markInactive(id: event.sessionId)
        }

        // Notifications & sounds
        switch event.eventType {
        case .stop:
            NotificationService.shared.postSessionFinished(sessionId: event.sessionId)
            NotificationService.shared.playSound(.needsInput)
        case .postToolUse:
            if let status = event.status, status == "error" || status == "failure" {
                NotificationService.shared.postToolError(sessionId: event.sessionId, toolName: event.toolName)
            }
        default:
            break
        }

        // Activity feed
        let shortId = String(event.sessionId.prefix(6))
        switch event.eventType {
        case .sessionStart:
            ActivityFeed.shared.add(icon: "▶", text: "Session started (\(shortId))")
        case .preToolUse:
            if let tool = event.toolName {
                ActivityFeed.shared.add(icon: "⚡", text: NotificationService.sanitize(tool, maxLength: 60))
            }
        case .stop:
            ActivityFeed.shared.add(icon: "✓", text: "Session complete")
        case .sessionEnd:
            ActivityFeed.shared.add(icon: "💤", text: "Session ended")
        case .preCompact:
            ActivityFeed.shared.add(icon: "!", text: "Compacting context")
        default:
            break
        }

        // Broadcast effective state to the room
        broadcastCurrentState()

        // Update session stats tracking
        updateStatsTracking()

        // Update gamification (streaks, achievements)
        updateGamification(event)
    }

    /// Push the current effective session state to RoomManager for network broadcast.
    func broadcastCurrentState() {
        let effective = sessionStore.effectiveSession
        let task = effective?.state.task ?? .idle
        let emotion = effective?.state.emotion ?? .neutral
        RoomManager.shared.broadcastState(task: task, emotion: emotion)

        // Record mood for sparkline
        SessionStats.shared.recordMood(emotion.rawValue)
    }

    private func updateGamification(_ event: HookEvent) {
        let store = GamificationStore.shared
        switch event.eventType {
        case .sessionStart:
            store.recordSessionStart()
        case .sessionEnd:
            let session = sessionStore.sessions.first { $0.id == event.sessionId }
            let duration = session.map { Date().timeIntervalSince($0.startedAt) } ?? 0
            let hour = Calendar.current.component(.hour, from: session?.startedAt ?? Date())
            store.recordSessionEnd(duration: duration, startHour: hour)
        case .preToolUse:
            store.recordToolUse()
            // Speed demon: check if session has 5+ tools in 30 seconds
            if let session = sessionStore.sessions.first(where: { $0.id == event.sessionId }) {
                let recentTools = session.recentToolTimes.filter {
                    Date().timeIntervalSince($0) < 30
                }
                if recentTools.count >= 5 {
                    store.recordSpeedBurst()
                }
            }
        default:
            break
        }
    }

    private func updateStatsTracking() {
        let hasActive = !sessionStore.activeSessions.isEmpty
        if hasActive {
            SessionStats.shared.startTracking()
        } else {
            SessionStats.shared.stopTracking()
        }
    }
}
