import Foundation
import SwiftUI

/// Every unlockable achievement in Clautch.
enum AchievementId: String, Codable, CaseIterable, Identifiable {
    // Session milestones
    case firstSession
    case tenSessions
    case fiftySessions

    // Time milestones
    case marathon       // 4+ hour single session
    case nightOwl       // session active past midnight
    case earlyBird      // session started before 6 AM

    // Activity milestones
    case bugSquasher    // 100 cumulative tool uses
    case speedDemon     // 5+ tools in 30 seconds

    // Social milestones
    case teamPlayer     // join a room
    case socialButterfly // send 10 reactions

    // Streak milestones
    case streakThree
    case streakSeven
    case streakThirty

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstSession:     return "Hello World"
        case .tenSessions:      return "Regular"
        case .fiftySessions:    return "Veteran"
        case .marathon:         return "Marathon"
        case .nightOwl:         return "Night Owl"
        case .earlyBird:        return "Early Bird"
        case .bugSquasher:      return "Bug Squasher"
        case .speedDemon:       return "Speed Demon"
        case .teamPlayer:       return "Team Player"
        case .socialButterfly:  return "Social Butterfly"
        case .streakThree:      return "On a Roll"
        case .streakSeven:      return "Week Warrior"
        case .streakThirty:     return "Unstoppable"
        }
    }

    var description: String {
        switch self {
        case .firstSession:     return "Complete your first session"
        case .tenSessions:      return "Complete 10 sessions"
        case .fiftySessions:    return "Complete 50 sessions"
        case .marathon:         return "Code for 4+ hours straight"
        case .nightOwl:         return "Code past midnight"
        case .earlyBird:        return "Start a session before 6 AM"
        case .bugSquasher:      return "Use 100 tools"
        case .speedDemon:       return "5 tools in 30 seconds"
        case .teamPlayer:       return "Join a room"
        case .socialButterfly:  return "Send 10 reactions"
        case .streakThree:      return "3-day coding streak"
        case .streakSeven:      return "7-day coding streak"
        case .streakThirty:     return "30-day coding streak"
        }
    }

    /// 5x5 pixel art badge. 0=clear, 1=primary, 2=secondary.
    var pixels: [[Int]] {
        switch self {
        case .firstSession:
            return [
                [0,0,1,0,0],
                [0,1,2,1,0],
                [1,2,2,2,1],
                [0,1,2,1,0],
                [0,0,1,0,0],
            ]
        case .tenSessions:
            return [
                [1,0,0,0,1],
                [1,0,1,0,1],
                [1,0,1,0,1],
                [1,0,1,0,1],
                [1,0,1,0,1],
            ]
        case .fiftySessions:
            return [
                [1,1,1,1,1],
                [1,0,0,0,0],
                [1,1,1,1,0],
                [0,0,0,1,0],
                [1,1,1,1,0],
            ]
        case .marathon:
            return [
                [0,2,2,2,0],
                [2,1,1,1,2],
                [2,1,2,1,2],
                [2,1,1,1,2],
                [0,2,2,2,0],
            ]
        case .nightOwl:
            return [
                [0,1,1,1,0],
                [1,2,0,2,1],
                [1,1,1,1,1],
                [0,1,0,1,0],
                [0,1,0,1,0],
            ]
        case .earlyBird:
            return [
                [0,0,2,0,0],
                [0,2,2,2,0],
                [1,1,2,1,1],
                [0,1,1,1,0],
                [0,0,1,0,0],
            ]
        case .bugSquasher:
            return [
                [0,1,0,1,0],
                [1,1,1,1,1],
                [1,2,1,2,1],
                [1,1,1,1,1],
                [0,1,0,1,0],
            ]
        case .speedDemon:
            return [
                [0,0,1,1,0],
                [0,1,1,0,0],
                [1,1,1,1,1],
                [0,1,1,0,0],
                [0,0,1,1,0],
            ]
        case .teamPlayer:
            return [
                [1,0,0,0,1],
                [1,1,0,1,1],
                [0,1,1,1,0],
                [1,1,0,1,1],
                [1,0,0,0,1],
            ]
        case .socialButterfly:
            return [
                [1,0,0,0,1],
                [1,1,0,1,1],
                [1,2,1,2,1],
                [1,1,0,1,1],
                [1,0,0,0,1],
            ]
        case .streakThree:
            return [
                [0,0,2,0,0],
                [0,2,1,0,0],
                [0,1,1,1,0],
                [1,1,1,1,1],
                [0,1,1,1,0],
            ]
        case .streakSeven:
            return [
                [0,2,2,2,0],
                [2,1,1,1,2],
                [1,1,1,1,1],
                [1,1,1,1,1],
                [0,1,1,1,0],
            ]
        case .streakThirty:
            return [
                [2,2,2,2,2],
                [2,1,1,1,2],
                [1,1,1,1,1],
                [1,1,1,1,1],
                [0,1,1,1,0],
            ]
        }
    }

    var primaryColor: Color {
        switch self {
        case .firstSession:     return Color(red: 0.3, green: 0.8, blue: 0.4)
        case .tenSessions:      return Color(red: 0.3, green: 0.7, blue: 0.9)
        case .fiftySessions:    return Color(red: 0.6, green: 0.4, blue: 0.9)
        case .marathon:         return Color(red: 0.9, green: 0.7, blue: 0.2)
        case .nightOwl:         return Color(red: 0.4, green: 0.3, blue: 0.7)
        case .earlyBird:        return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .bugSquasher:      return Color(red: 0.8, green: 0.2, blue: 0.2)
        case .speedDemon:       return Color(red: 0.0, green: 0.8, blue: 0.9)
        case .teamPlayer:       return Color(red: 0.3, green: 0.6, blue: 0.9)
        case .socialButterfly:  return Color(red: 0.9, green: 0.4, blue: 0.6)
        case .streakThree:      return Color(red: 1.0, green: 0.5, blue: 0.0)
        case .streakSeven:      return Color(red: 1.0, green: 0.4, blue: 0.0)
        case .streakThirty:     return Color(red: 1.0, green: 0.3, blue: 0.0)
        }
    }

    var secondaryColor: Color {
        switch self {
        case .firstSession:     return Color(red: 0.9, green: 1.0, blue: 0.5)
        case .tenSessions:      return Color(red: 0.6, green: 0.9, blue: 1.0)
        case .fiftySessions:    return Color(red: 0.8, green: 0.6, blue: 1.0)
        case .marathon:         return Color(red: 1.0, green: 0.9, blue: 0.5)
        case .nightOwl:         return Color(red: 0.7, green: 0.6, blue: 1.0)
        case .earlyBird:        return Color(red: 1.0, green: 0.85, blue: 0.3)
        case .bugSquasher:      return Color(red: 1.0, green: 0.5, blue: 0.4)
        case .speedDemon:       return Color(red: 0.5, green: 1.0, blue: 1.0)
        case .teamPlayer:       return Color(red: 0.6, green: 0.8, blue: 1.0)
        case .socialButterfly:  return Color(red: 1.0, green: 0.7, blue: 0.85)
        case .streakThree:      return Color(red: 1.0, green: 0.85, blue: 0.2)
        case .streakSeven:      return Color(red: 1.0, green: 0.8, blue: 0.1)
        case .streakThirty:     return Color(red: 1.0, green: 0.95, blue: 0.4)
        }
    }
}

/// A single earned achievement record.
struct EarnedAchievement: Codable, Identifiable {
    let achievementId: AchievementId
    let earnedAt: Date

    var id: String { achievementId.rawValue }
}
