import Foundation

/// Represents one active Claude Code session.
@Observable
@MainActor
final class SessionData: Identifiable {
    let id: String            // Claude Code session ID
    var state: CreatureState  = CreatureState()
    var xPosition: CGFloat    = 0.5  // normalized 0…1 position on the island
    let startedAt: Date       = Date()
    var lastToolName: String?

    // MARK: - Sentiment Tracking

    /// Consecutive error count (resets on success).
    private var errorStreak: Int = 0

    /// Recent tool timestamps for velocity detection.
    private var recentToolTimes: [Date] = []

    /// Number of permission requests in this session.
    private var permissionRequestCount: Int = 0

    private var emotionResetTask: Task<Void, Never>?

    init(id: String) {
        self.id = id
        self.xPosition = CGFloat.random(in: 0.2...0.8)
    }

    /// Map a hook event to a creature task transition with sentiment analysis.
    func applyEvent(_ event: HookEvent) {
        state.lastActivity = Date()

        // Clear attention flags when user submits a prompt
        if event.eventType == .promptSubmit || event.eventType == .sessionStart {
            state.needsInput = false
            state.needsPermission = false
        }

        switch event.eventType {
        case .sessionStart:
            state.task = .idle
            state.emotion = .neutral
            errorStreak = 0

        case .promptSubmit:
            state.task = .thinking

        case .preToolUse:
            state.task = .working
            lastToolName = event.toolName
            recentToolTimes.append(Date())
            // Keep only last 10
            if recentToolTimes.count > 10 {
                recentToolTimes.removeFirst()
            }

        case .postToolUse:
            state.task = .thinking
            lastToolName = event.toolName

            if let status = event.status {
                if status == "success" {
                    errorStreak = 0
                    // Check tool velocity: 5+ tools in last 30 seconds = excited
                    let recentCount = recentToolTimes.filter {
                        Date().timeIntervalSince($0) < 30
                    }.count
                    if recentCount >= 5 {
                        setEmotionTemporarily(.excited)
                    } else {
                        setEmotionTemporarily(.happy)
                    }
                } else if status == "error" || status == "failure" {
                    errorStreak += 1
                    if errorStreak >= 3 {
                        setEmotionTemporarily(.frustrated, duration: 8.0)
                    } else {
                        setEmotionTemporarily(.sad)
                    }
                }
            }

        case .stop:
            state.task = .idle
            state.needsInput = true
            errorStreak = 0
            // Long session (>30 min) = tired, otherwise happy
            let sessionLength = Date().timeIntervalSince(startedAt)
            if sessionLength > 1800 {
                setEmotionTemporarily(.tired, duration: 5.0)
            } else {
                setEmotionTemporarily(.happy, duration: 3.0)
            }

        case .sessionEnd:
            state.task = .sleeping
            state.emotion = .neutral
            errorStreak = 0

        case .preCompact:
            state.task = .compacting
            setEmotionTemporarily(.tired, duration: 8.0)

        case .permissionRequest:
            state.task = .thinking
            state.needsPermission = true
            permissionRequestCount += 1
            if permissionRequestCount >= 3 {
                setEmotionTemporarily(.confused, duration: 4.0)
            }
        }
    }

    private func setEmotionTemporarily(_ emotion: CreatureEmotion, duration: TimeInterval = 5.0) {
        state.emotion = emotion
        emotionResetTask?.cancel()
        emotionResetTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            state.emotion = .neutral
        }
    }
}
