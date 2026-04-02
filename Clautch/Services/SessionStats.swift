import Foundation
import os

/// Tracks cumulative Claude Code session time per day.
@Observable
@MainActor
final class SessionStats {
    static let shared = SessionStats()

    private let logger = Logger(subsystem: "com.clautch.app", category: "SessionStats")
    private static let storageKey = "com.clautch.sessionStats"

    /// Daily totals: ["2026-03-31": 3600.0] (seconds)
    private(set) var dailyTotals: [String: TimeInterval] = [:]

    /// When the current active tracking started (nil if not tracking).
    private var trackingStart: Date?
    private var trackingTimer: Timer?

    private init() {
        loadFromDefaults()
    }

    // MARK: - Public

    /// Start tracking active session time.
    func startTracking() {
        guard trackingStart == nil else { return }
        trackingStart = Date()
        // Flush accumulated time every 30 seconds
        trackingTimer?.invalidate()
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.flushCurrentSession()
            }
        }
    }

    /// Stop tracking and flush remaining time.
    func stopTracking() {
        flushCurrentSession()
        trackingStart = nil
        trackingTimer?.invalidate()
        trackingTimer = nil
    }

    /// Today's total session time in seconds.
    var todayTotal: TimeInterval {
        let key = Self.dateKey(for: Date())
        let stored = dailyTotals[key] ?? 0
        // Add in-progress time
        if let start = trackingStart {
            return stored + Date().timeIntervalSince(start)
        }
        return stored
    }

    /// This week's total session time in seconds (Mon–Sun).
    var weekTotal: TimeInterval {
        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return todayTotal
        }
        var total: TimeInterval = 0
        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            if day > today { break }
            let key = Self.dateKey(for: day)
            total += dailyTotals[key] ?? 0
        }
        // Add in-progress time for today
        if let start = trackingStart {
            total += Date().timeIntervalSince(start)
        }
        return total
    }

    /// Daily totals for the current week (Mon–Sun), ordered by day.
    var weekDays: [(label: String, seconds: TimeInterval)] {
        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return []
        }
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        var result: [(String, TimeInterval)] = []
        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            let key = Self.dateKey(for: day)
            var total = dailyTotals[key] ?? 0
            // Add in-progress time for today
            if key == Self.dateKey(for: today), let start = trackingStart {
                total += Date().timeIntervalSince(start)
            }
            result.append((dayFormatter.string(from: day), total))
        }
        return result
    }

    /// Format seconds as "Xh Ym".
    static func format(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    /// Label showing when the week resets (e.g. "Mon" or "in 2d").
    static var weekResetLabel: String {
        let calendar = Calendar.current
        let today = Date()
        guard let weekEnd = calendar.dateInterval(of: .weekOfYear, for: today)?.end else {
            return "Mon"
        }
        let daysUntil = calendar.dateComponents([.day], from: today, to: weekEnd).day ?? 0
        if daysUntil <= 1 { return "tomorrow" }
        return "in \(daysUntil)d"
    }

    // MARK: - Private

    private func flushCurrentSession() {
        guard let start = trackingStart else { return }
        let elapsed = Date().timeIntervalSince(start)
        guard elapsed > 0 else { return }

        let key = Self.dateKey(for: Date())
        dailyTotals[key, default: 0] += elapsed
        trackingStart = Date()
        saveToDefaults()
    }

    private static func dateKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func loadFromDefaults() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([String: TimeInterval].self, from: data) {
            dailyTotals = decoded
        }
        // Prune entries older than 30 days
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let cutoffKey = Self.dateKey(for: cutoff)
        dailyTotals = dailyTotals.filter { $0.key >= cutoffKey }
    }

    private func saveToDefaults() {
        if let data = try? JSONEncoder().encode(dailyTotals) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
