import Foundation

/// A single activity event for the feed.
struct ActivityItem: Identifiable {
    let id = UUID()
    let icon: String   // SF Symbol or emoji-like label
    let text: String
    let timestamp: Date

    var timeAgo: String {
        let seconds = Int(Date().timeIntervalSince(timestamp))
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h"
    }
}

/// Observable feed of recent activity (max 5 items).
@Observable
@MainActor
final class ActivityFeed {
    static let shared = ActivityFeed()

    private(set) var items: [ActivityItem] = []
    private let maxItems = 5

    private init() {}

    func add(icon: String, text: String) {
        let item = ActivityItem(icon: icon, text: text, timestamp: Date())
        items.insert(item, at: 0)
        if items.count > maxItems {
            items.removeLast()
        }
    }
}
