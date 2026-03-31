import Foundation

/// Represents one active Claude Code session.
@Observable
@MainActor
final class SessionData: Identifiable {
    let id: String            // Claude Code session ID
    var state: CreatureState  = CreatureState()
    var xPosition: CGFloat    = 0.5  // normalized 0…1 position on the island
    let startedAt: Date       = Date()

    private var emotionResetTask: Task<Void, Never>?

    init(id: String) {
        self.id = id
        self.xPosition = CGFloat.random(in: 0.2...0.8)
    }

    /// Map a hook event to a creature task transition.
    func applyEvent(_ event: HookEvent) {
        state.lastActivity = Date()

        switch event.eventType {
        case .sessionStart:
            state.task = .idle
            state.emotion = .neutral
        case .promptSubmit:
            state.task = .thinking
        case .preToolUse:
            state.task = .working
        case .postToolUse:
            state.task = .thinking
            // Trigger emotion based on tool result
            if let status = event.status {
                if status == "success" {
                    setEmotionTemporarily(.happy)
                } else if status == "error" || status == "failure" {
                    setEmotionTemporarily(.sad)
                }
            }
        case .stop:
            state.task = .idle
            setEmotionTemporarily(.happy, duration: 3.0)
        case .sessionEnd:
            state.task = .sleeping
            state.emotion = .neutral
        case .preCompact:
            state.task = .compacting
            setEmotionTemporarily(.sad, duration: 8.0)
        case .permissionRequest:
            state.task = .thinking
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
