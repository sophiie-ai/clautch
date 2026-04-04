import Foundation

/// Persisted streak state for daily coding streaks.
struct StreakData: Codable {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastActiveDate: String?   // "yyyy-MM-dd" — matches SessionStats.dateKey
    var streakStartDate: String?  // when the current streak began
}
