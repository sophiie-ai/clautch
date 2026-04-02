import Foundation

/// Tracks all active Claude Code sessions.
@Observable
@MainActor
final class SessionStore {
    private(set) var sessions: [SessionData] = []

    /// Cached derived state — invalidated on mutations.
    private(set) var activeSessions: [SessionData] = []
    private(set) var effectiveSession: SessionData?

    private func refreshDerived() {
        let active = sessions.filter { $0.state.isActive }
        activeSessions = active
        effectiveSession = active
            .sorted { $0.state.lastActivity > $1.state.lastActivity }
            .first
    }

    func getOrCreate(id: String) -> SessionData {
        if let existing = sessions.first(where: { $0.id == id }) {
            return existing
        }
        let session = SessionData(id: id)
        sessions.append(session)
        refreshDerived()
        return session
    }

    func markInactive(id: String) {
        if let session = sessions.first(where: { $0.id == id }) {
            session.state.task = .sleeping
            refreshDerived()
        }
    }

    /// Refresh derived state after external mutations (e.g. session state changes).
    func invalidateCache() {
        refreshDerived()
    }

    /// Remove sessions that have been inactive for more than 5 minutes.
    func cleanupStale() {
        let before = sessions.count
        sessions.removeAll { session in
            Date().timeIntervalSince(session.state.lastActivity) > 300
        }
        if sessions.count != before {
            refreshDerived()
        }
    }
}
