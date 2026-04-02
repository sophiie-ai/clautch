import Foundation

/// Tracks all active Claude Code sessions.
@Observable
@MainActor
final class SessionStore {
    private(set) var sessions: [SessionData] = []

    /// Sessions that have had activity in the last 60 seconds.
    var activeSessions: [SessionData] {
        sessions.filter { $0.state.isActive }
    }

    /// The primary session (most recently active).
    var effectiveSession: SessionData? {
        activeSessions
            .sorted { $0.state.lastActivity > $1.state.lastActivity }
            .first
    }

    func getOrCreate(id: String) -> SessionData {
        if let existing = sessions.first(where: { $0.id == id }) {
            return existing
        }
        let session = SessionData(id: id)
        sessions.append(session)
        return session
    }

    func markInactive(id: String) {
        if let session = sessions.first(where: { $0.id == id }) {
            session.state.task = .sleeping
        }
    }

    /// Remove sessions that have been inactive for more than 5 minutes.
    func cleanupStale() {
        sessions.removeAll { session in
            Date().timeIntervalSince(session.state.lastActivity) > 300
        }
    }
}
