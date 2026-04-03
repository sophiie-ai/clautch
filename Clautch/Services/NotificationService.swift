import Foundation
import UserNotifications
import os

/// Sends macOS notifications for session events (completion, errors).
@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private let logger = Logger(subsystem: "com.clautch.app", category: "Notifications")

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "com.clautch.notificationsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "com.clautch.notificationsEnabled") }
    }

    /// Coalescing window — batch rapid peer events into grouped notifications.
    private var pendingPeerEvents: [(String, String)] = []  // (title, body)
    private var coalesceTask: Task<Void, Never>?
    private let coalesceDelay: TimeInterval = 2.5

    private init() {}

    func requestPermissionIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error { self.logger.error("Notification auth error: \(error.localizedDescription)") }
        }
    }

    func postSessionFinished(sessionId: String) {
        guard isEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "Session Complete"
        content.body = "Claude Code session \(String(sessionId.prefix(8)))… finished."
        content.sound = .default
        let request = UNNotificationRequest(identifier: "stop-\(sessionId)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func postToolError(sessionId: String, toolName: String?) {
        guard isEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "Tool Error"
        // Sanitize: truncate tool name and strip control characters
        let safeName = sanitize(toolName ?? "Unknown tool", maxLength: 60)
        content.body = "\(safeName) failed in session \(String(sessionId.prefix(8)))…"
        content.sound = .default
        let id = "error-\(sessionId)-\(Int(Date().timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func postReactionReceived(from peerName: String, reaction: PeerReaction) {
        guard isEnabled else { return }
        enqueuePeerEvent(title: "\(peerName) reacted", body: "\(reaction.emoji) \(reaction.rawValue.capitalized)")
    }

    func postChatReceived(from peerName: String, message: String) {
        guard isEnabled else { return }
        enqueuePeerEvent(title: peerName, body: sanitize(message, maxLength: 50))
    }

    /// Enqueue a peer event — coalesces rapid events into a single grouped notification.
    private func enqueuePeerEvent(title: String, body: String) {
        pendingPeerEvents.append((title, body))

        // Reset the coalesce timer
        coalesceTask?.cancel()
        coalesceTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(coalesceDelay))
            guard !Task.isCancelled else { return }
            flushPeerEvents()
        }
    }

    /// Flush pending peer events into one or more notifications.
    private func flushPeerEvents() {
        guard !pendingPeerEvents.isEmpty else { return }
        let events = pendingPeerEvents
        pendingPeerEvents.removeAll()

        let content = UNMutableNotificationContent()
        if events.count == 1 {
            content.title = events[0].0
            content.body = events[0].1
        } else {
            content.title = "Clautch Room"
            content.body = events.prefix(4).map { "\($0.0): \($0.1)" }.joined(separator: "\n")
            if events.count > 4 {
                content.body += "\n+\(events.count - 4) more"
            }
        }
        content.sound = .default
        content.threadIdentifier = "clautch-room"

        let id = "room-\(Int(Date().timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func sanitize(_ text: String, maxLength: Int) -> String {
        let cleaned = text.unicodeScalars.filter { scalar in
            // Remove control characters and invisible formatting
            let category = scalar.properties.generalCategory
            return category != .control && category != .format
        }
        let result = String(String.UnicodeScalarView(cleaned))
        return String(result.prefix(maxLength))
    }
}
