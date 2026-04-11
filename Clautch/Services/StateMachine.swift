import Foundation
import os

/// Central event processor: receives hook events and updates session state.
/// Also broadcasts state changes to the room via RoomManager.
@Observable
@MainActor
final class StateMachine {
    static let shared = StateMachine()

    let sessionStore = SessionStore()
    private(set) var activeStatus: UserStatus?
    private let logger = Logger(subsystem: "com.clautch.app", category: "StateMachine")
    private var cleanupTimer: Timer?
    private static let statusKey = "com.clautch.activeStatus"

    private init() {
        // Wire up socket events → state transitions
        SocketServer.shared.onEvent = { [weak self] event in
            Task { @MainActor in
                self?.handleEvent(event)
            }
        }

        // Load persisted status
        if let data = UserDefaults.standard.data(forKey: Self.statusKey),
           let status = try? JSONDecoder().decode(UserStatus.self, from: data),
           !status.isExpired {
            activeStatus = status
        }

        // Periodic cleanup of stale sessions + status expiry check
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sessionStore.cleanupStale()
                self?.checkStatusExpiry()
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

    // MARK: - Status

    /// Set a status from a preset with optional custom text and expiry duration.
    func setStatus(preset: StatusPreset, customText: String? = nil, expiry: TimeInterval? = nil) {
        let duration = expiry ?? preset.defaultExpiry
        let status = UserStatus(
            preset: preset,
            customText: customText,
            setAt: Date(),
            expiresAt: Date().addingTimeInterval(duration)
        )
        activeStatus = status
        persistStatus()
        GamificationStore.shared.recordStatusSet()
        ActivityFeed.shared.add(icon: preset.emoji, text: "Status: \(status.displayText)")
        broadcastCurrentState()
        logger.info("Status set: \(preset.rawValue) expires in \(Int(duration))s")
    }

    /// Set a custom status with freeform text.
    func setCustomStatus(text: String, expiry: TimeInterval) {
        let sanitized = NotificationService.sanitize(text, maxLength: 100)
        guard !sanitized.isEmpty else { return }
        let status = UserStatus(
            preset: nil,
            customText: sanitized,
            setAt: Date(),
            expiresAt: Date().addingTimeInterval(expiry)
        )
        activeStatus = status
        persistStatus()
        GamificationStore.shared.recordStatusSet()
        ActivityFeed.shared.add(icon: "\u{1F4AC}", text: "Status: \(sanitized)")
        broadcastCurrentState()
        logger.info("Custom status set: \(sanitized)")
    }

    /// Clear the current status.
    func clearStatus() {
        guard activeStatus != nil else { return }
        activeStatus = nil
        persistStatus()
        ActivityFeed.shared.add(icon: "\u{2716}", text: "Status cleared")
        broadcastCurrentState()
        logger.info("Status cleared")
    }

    private func checkStatusExpiry() {
        guard let status = activeStatus, status.isExpired else { return }
        activeStatus = nil
        persistStatus()
        ActivityFeed.shared.add(icon: "\u{23F0}", text: "Status expired")
        broadcastCurrentState()
        logger.info("Status auto-expired")
    }

    private func persistStatus() {
        if let status = activeStatus,
           let data = try? JSONEncoder().encode(status) {
            UserDefaults.standard.set(data, forKey: Self.statusKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.statusKey)
        }
    }

    /// Push the current effective session state to RoomManager for network broadcast.
    func broadcastCurrentState() {
        let effective = sessionStore.effectiveSession
        var task = effective?.state.task ?? .idle
        var emotion = effective?.state.emotion ?? .neutral

        // When idle with no session, apply local interaction emotion if active
        if effective == nil, let interactionEmo = interactionEmotion {
            emotion = interactionEmo
        }

        // Status only overrides when Claude Code is idle — active thinking/working takes priority
        let claudeActive = task == .thinking || task == .working
        if let status = activeStatus, !status.isExpired, !claudeActive, let preset = status.preset {
            task = preset.creatureTask
            emotion = preset.creatureEmotion
        }

        RoomManager.shared.broadcastState(task: task, emotion: emotion)

        // Record mood for sparkline and gamification
        SessionStats.shared.recordMood(emotion.rawValue)
        GamificationStore.shared.recordMoodSample(emotion.rawValue)
    }

    // MARK: - Local Interactions (pet, poke, feed)

    enum LocalInteraction {
        case pet, poke, feed
    }

    /// Tracks the emotion that was set by the last local interaction, so the
    /// reset task only clears it if no newer emotion has arrived in the meantime.
    private var interactionEmotion: CreatureEmotion?
    private var interactionResetTask: Task<Void, Never>?

    /// Apply a local user interaction (pet/poke/feed) to the creature's mood.
    /// Works even when no Claude session is active by setting a local override.
    func applyLocalInteraction(_ type: LocalInteraction) {
        let emotion: CreatureEmotion
        let duration: Double
        switch type {
        case .pet:
            emotion = .happy
            duration = 3.0
            GamificationStore.shared.recordInteraction(.pet)
        case .poke:
            emotion = .confused
            duration = 2.0
            GamificationStore.shared.recordInteraction(.poke)
        case .feed:
            emotion = .happy
            duration = 5.0
            GamificationStore.shared.recordInteraction(.feed)
        }

        // Apply to effective session if one exists
        if let effective = sessionStore.effectiveSession {
            effective.state.emotion = emotion
        }

        // Track which emotion we set so the reset is safe
        interactionEmotion = emotion
        interactionResetTask?.cancel()
        interactionResetTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            // Only reset if the emotion is still the one we set
            if let effective = sessionStore.effectiveSession,
               effective.state.emotion == interactionEmotion {
                effective.state.emotion = .neutral
            }
            interactionEmotion = nil
            sessionStore.invalidateCache()
            broadcastCurrentState()
        }

        sessionStore.invalidateCache()
        broadcastCurrentState()
    }

    /// Track per-session error streaks for recovery detection.
    private var sessionErrorStreaks: [String: Int] = [:]

    private func updateGamification(_ event: HookEvent) {
        let store = GamificationStore.shared
        switch event.eventType {
        case .sessionStart:
            store.recordSessionStart()
            // Milestone session journal entries
            let total = store.counters.totalSessions
            if [10, 25, 50, 100, 250, 500].contains(total) {
                JournalStore.shared.record(type: .milestoneSession, title: "Session #\(total)", detail: "A coding milestone!")
            }
        case .sessionEnd:
            let session = sessionStore.sessions.first { $0.id == event.sessionId }
            let duration = session.map { Date().timeIntervalSince($0.startedAt) } ?? 0
            let hour = Calendar.current.component(.hour, from: session?.startedAt ?? Date())
            store.recordSessionEnd(duration: duration, startHour: hour)
            // Record coding time for time-based achievements
            store.recordCodingTime(duration)
            sessionErrorStreaks.removeValue(forKey: event.sessionId)
        case .preToolUse:
            store.recordToolUse()
            if let toolName = event.toolName {
                store.recordToolName(toolName)
            }
            // Speed demon + velocity bonus: check if session has 5+ tools in 30 seconds
            if let session = sessionStore.sessions.first(where: { $0.id == event.sessionId }) {
                let recentTools = session.recentToolTimes.filter {
                    Date().timeIntervalSince($0) < 30
                }
                if recentTools.count >= 5 {
                    store.recordSpeedBurst()
                    store.recordToolVelocityBonus()
                }
            }
        case .postToolUse:
            // Track error recovery: 3+ errors → success = recovery
            let sid = event.sessionId
            if let status = event.status {
                if status == "error" || status == "failure" {
                    sessionErrorStreaks[sid, default: 0] += 1
                } else if status == "success" {
                    let previousErrors = sessionErrorStreaks[sid] ?? 0
                    if previousErrors >= 3 {
                        store.recordErrorRecovery()
                    }
                    sessionErrorStreaks[sid] = 0
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
