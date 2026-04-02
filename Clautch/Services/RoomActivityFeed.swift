import Foundation

/// A single room activity event (chat, join, leave, reaction).
struct RoomEvent: Identifiable {
    let id = UUID()
    let kind: Kind
    let peerName: String
    let text: String
    let timestamp: Date

    enum Kind: String {
        case chat
        case join
        case leave
        case reaction
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

/// Observable feed of room activity events (max 30 items, pruned on insert).
@Observable
@MainActor
final class RoomActivityFeed {
    static let shared = RoomActivityFeed()

    private(set) var events: [RoomEvent] = []
    private let maxEvents = 30

    private init() {}

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
    }

    private func insert(_ event: RoomEvent) {
        events.insert(event, at: 0)
        if events.count > maxEvents {
            events.removeLast()
        }
    }
}
