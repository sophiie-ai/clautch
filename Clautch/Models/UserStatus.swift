import Foundation
import SwiftUI

// MARK: - Status Preset

/// Predefined status types a user can set.
enum StatusPreset: String, CaseIterable, Codable, Sendable, Identifiable {
    case deepWork
    case lunch
    case inMeeting
    case ooo
    case afk

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .deepWork:  return "Deep Work"
        case .lunch:     return "Lunch"
        case .inMeeting: return "In a Meeting"
        case .ooo:       return "OOO"
        case .afk:       return "AFK"
        }
    }

    var emoji: String {
        switch self {
        case .deepWork:  return "\u{1F3AF}" // target
        case .lunch:     return "\u{1F355}" // pizza
        case .inMeeting: return "\u{1F4DE}" // phone
        case .ooo:       return "\u{1F3D6}" // beach
        case .afk:       return "\u{1F4A4}" // zzz
        }
    }

    /// Default auto-expire duration in seconds.
    var defaultExpiry: TimeInterval {
        switch self {
        case .deepWork:  return 2 * 3600    // 2 hours
        case .lunch:     return 90 * 60     // 90 minutes
        case .inMeeting: return 60 * 60     // 1 hour
        case .ooo:       return 8 * 3600    // 8 hours
        case .afk:       return 4 * 3600    // 4 hours
        }
    }

    /// The creature task to display while this status is active.
    var creatureTask: CreatureTask {
        switch self {
        case .deepWork:  return .working
        case .lunch:     return .idle
        case .inMeeting: return .thinking
        case .ooo:       return .sleeping
        case .afk:       return .sleeping
        }
    }

    /// The creature emotion to display while this status is active.
    var creatureEmotion: CreatureEmotion {
        switch self {
        case .deepWork:  return .neutral
        case .lunch:     return .happy
        case .inMeeting: return .neutral
        case .ooo:       return .neutral
        case .afk:       return .tired
        }
    }

    /// 4x3 pixel art icon for the status badge.
    /// Pixel codes: 0=clear, 8=status primary, 9=status secondary.
    var badgePixels: [[Int]] {
        switch self {
        case .deepWork:
            // Headphones
            return [
                [8,0,0,8],
                [8,9,9,8],
                [0,0,0,0],
            ]
        case .lunch:
            // Fork/plate
            return [
                [0,9,9,0],
                [8,9,9,8],
                [0,8,8,0],
            ]
        case .inMeeting:
            // Speech bubble
            return [
                [8,8,8,8],
                [8,9,9,8],
                [8,0,0,0],
            ]
        case .ooo:
            // Palm tree
            return [
                [0,9,9,0],
                [9,8,9,0],
                [0,8,0,0],
            ]
        case .afk:
            // Moon
            return [
                [0,8,8,0],
                [8,0,9,8],
                [0,8,8,0],
            ]
        }
    }

    var badgePrimaryColor: Color {
        switch self {
        case .deepWork:  return Color(red: 0.3, green: 0.6, blue: 1.0)
        case .lunch:     return Color(red: 1.0, green: 0.7, blue: 0.2)
        case .inMeeting: return Color(red: 0.5, green: 0.8, blue: 0.4)
        case .ooo:       return Color(red: 0.3, green: 0.8, blue: 0.7)
        case .afk:       return Color(red: 0.6, green: 0.5, blue: 0.9)
        }
    }

    var badgeSecondaryColor: Color {
        switch self {
        case .deepWork:  return Color(red: 0.5, green: 0.8, blue: 1.0)
        case .lunch:     return Color(red: 1.0, green: 0.9, blue: 0.5)
        case .inMeeting: return Color(red: 0.8, green: 1.0, blue: 0.7)
        case .ooo:       return Color(red: 0.5, green: 1.0, blue: 0.9)
        case .afk:       return Color(red: 0.8, green: 0.7, blue: 1.0)
        }
    }
}

// MARK: - User Status

/// A user's active status, persisted locally and synced via CloudKit.
struct UserStatus: Codable, Sendable {
    let preset: StatusPreset?
    let customText: String?
    let setAt: Date
    let expiresAt: Date

    var isExpired: Bool { Date() >= expiresAt }

    var displayText: String {
        if let custom = customText, !custom.isEmpty { return custom }
        return preset?.displayName ?? ""
    }

    var displayEmoji: String {
        preset?.emoji ?? "\u{1F4AC}" // speech bubble fallback for custom
    }
}

// MARK: - Expiry Duration

/// Preset durations for status auto-expiry.
enum StatusExpiry: CaseIterable, Identifiable {
    case thirtyMinutes
    case oneHour
    case twoHours
    case fourHours
    case eightHours
    case endOfDay

    var id: String {
        switch self {
        case .thirtyMinutes: return "30m"
        case .oneHour:       return "1h"
        case .twoHours:      return "2h"
        case .fourHours:     return "4h"
        case .eightHours:    return "8h"
        case .endOfDay:      return "eod"
        }
    }

    var displayName: String {
        switch self {
        case .thirtyMinutes: return "30 minutes"
        case .oneHour:       return "1 hour"
        case .twoHours:      return "2 hours"
        case .fourHours:     return "4 hours"
        case .eightHours:    return "8 hours"
        case .endOfDay:      return "End of day"
        }
    }

    var duration: TimeInterval {
        switch self {
        case .thirtyMinutes: return 30 * 60
        case .oneHour:       return 3600
        case .twoHours:      return 2 * 3600
        case .fourHours:     return 4 * 3600
        case .eightHours:    return 8 * 3600
        case .endOfDay:
            let cal = Calendar.current
            let endOfDay = cal.startOfDay(for: Date()).addingTimeInterval(86399)
            return max(60, endOfDay.timeIntervalSinceNow)
        }
    }
}
