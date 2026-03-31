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
