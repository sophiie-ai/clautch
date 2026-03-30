import Foundation

/// Represents one active Claude Code session.
@Observable
@MainActor
final class SessionData: Identifiable {
    let id: String            // Claude Code session ID
    var state: CreatureState  = CreatureState()
    var xPosition: CGFloat    = 0.5  // normalized 0…1 position on the island

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
        case .promptSubmit:
            state.task = .thinking
        case .preToolUse:
            state.task = .working
        case .postToolUse:
            state.task = .thinking
        case .stop:
            state.task = .idle
        case .sessionEnd:
            state.task = .sleeping
        case .preCompact:
            state.task = .compacting
        case .permissionRequest:
            state.task = .thinking
        }
    }
}
