import Foundation

/// A single room activity event (chat, join, leave, reaction).
struct RoomEvent: Identifiable, Codable {
    let id: UUID
    let kind: Kind
    let peerName: String
    let text: String
    let timestamp: Date

    enum Kind: String, Codable {
        case chat
        case join
        case leave
        case reaction
    }

    init(kind: Kind, peerName: String, text: String, timestamp: Date) {
        self.id = UUID()
        self.kind = kind
        self.peerName = peerName
        self.text = text
        self.timestamp = timestamp
    }

    var timeAgo: String {
        let seconds = Int(Date().timeIntervalSince(timestamp))
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h"
    }

    var icon: String {
        switch kind {
        case .chat:     return "bubble.left"
        case .join:     return "person.badge.plus"
        case .leave:    return "person.badge.minus"
        case .reaction: return "sparkles"
        }
    }
}

/// Observable feed of room activity events (max 30 items).
/// Persists to disk so chat history survives app restarts.
@Observable
@MainActor
final class RoomActivityFeed {
    static let shared = RoomActivityFeed()

    private(set) var events: [RoomEvent] = []
    private let maxEvents = 30
    private static let storageKey = "com.clautch.roomActivityFeed"

    private init() {
        loadFromDisk()
    }

    func addChat(from peerName: String, message: String) {
        insert(RoomEvent(kind: .chat, peerName: peerName, text: message, timestamp: Date()))
    }

    func addJoin(_ peerName: String) {
        insert(RoomEvent(kind: .join, peerName: peerName, text: "\(peerName) joined", timestamp: Date()))
    }

    func addLeave(_ peerName: String) {
        insert(RoomEvent(kind: .leave, peerName: peerName, text: "\(peerName) left", timestamp: Date()))
    }

    func addReaction(from peerName: String, reaction: PeerReaction) {
        insert(RoomEvent(kind: .reaction, peerName: peerName, text: "\(peerName) reacted \(reaction.emoji)", timestamp: Date()))
    }

    func clear() {
        events.removeAll()
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }

    private func insert(_ event: RoomEvent) {
        events.insert(event, at: 0)
        if events.count > maxEvents {
            events.removeLast()
        }
        saveToDisk()
    }

    // MARK: - Persistence

    private func saveToDisk() {
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([RoomEvent].self, from: data) else { return }
        // Prune events older than 24 hours
        let cutoff = Date(timeIntervalSinceNow: -86400)
        events = decoded.filter { $0.timestamp > cutoff }.prefix(maxEvents).map { $0 }
    }
}
