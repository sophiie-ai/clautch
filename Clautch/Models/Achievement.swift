import Foundation
import SwiftUI

/// Every unlockable achievement in Clautch.
enum AchievementId: String, Codable, CaseIterable, Identifiable {
    // Session milestones
    case firstSession
    case fiveSessions
    case tenSessions
    case twentyFiveSessions
    case fiftySessions
    case hundredSessions

    // Time milestones
    case marathon       // 4+ hour single session
    case nightOwl       // session active past midnight
    case earlyBird      // session started before 6 AM

    // Coding time milestones
    case centurion      // 1 hour total coding time
    case dedicated      // 10 hours total coding time
    case ironclad       // 50 hours total coding time

    // Activity milestones
    case bugSquasher    // 100 cumulative tool uses
    case toolsmith      // 250 cumulative tool uses
    case prolific       // 500 cumulative tool uses
    case speedDemon     // 5+ tools in 30 seconds

    // Resilience
    case resilient      // recover from 3+ error streak

    // Mood
    case zenMaster      // 20+ positive mood samples in a row

    // Social milestones
    case teamPlayer     // join a room
    case socialButterfly // send 10 reactions

    // Status milestones
    case statusSetter   // set status 25 times

    // Streak milestones
    case streakThree
    case streakSeven
    case streakFourteen
    case streakThirty

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstSession:         return "Hello World"
        case .fiveSessions:         return "Getting Started"
        case .tenSessions:          return "Regular"
        case .twentyFiveSessions:   return "Dedicated Coder"
        case .fiftySessions:        return "Veteran"
        case .hundredSessions:      return "Centenarian"
        case .marathon:             return "Marathon"
        case .nightOwl:             return "Night Owl"
        case .earlyBird:            return "Early Bird"
        case .centurion:            return "Centurion"
        case .dedicated:            return "Dedicated"
        case .ironclad:             return "Ironclad"
        case .bugSquasher:          return "Bug Squasher"
        case .toolsmith:            return "Toolsmith"
        case .prolific:             return "Prolific"
        case .speedDemon:           return "Speed Demon"
        case .resilient:            return "Resilient"
        case .zenMaster:            return "Zen Master"
        case .teamPlayer:           return "Team Player"
        case .socialButterfly:      return "Social Butterfly"
        case .statusSetter:         return "Status Setter"
        case .streakThree:          return "On a Roll"
        case .streakSeven:          return "Week Warrior"
        case .streakFourteen:       return "Fortnight"
        case .streakThirty:         return "Unstoppable"
        }
    }

    var description: String {
        switch self {
        case .firstSession:         return "Complete your first session"
        case .fiveSessions:         return "Complete 5 sessions"
        case .tenSessions:          return "Complete 10 sessions"
        case .twentyFiveSessions:   return "Complete 25 sessions"
        case .fiftySessions:        return "Complete 50 sessions"
        case .hundredSessions:      return "Complete 100 sessions"
        case .marathon:             return "Code for 4+ hours straight"
        case .nightOwl:             return "Code past midnight"
        case .earlyBird:            return "Start a session before 6 AM"
        case .centurion:            return "1 hour of total coding"
        case .dedicated:            return "10 hours of total coding"
        case .ironclad:             return "50 hours of total coding"
        case .bugSquasher:          return "Use 100 tools"
        case .toolsmith:            return "Use 250 tools"
        case .prolific:             return "Use 500 tools"
        case .speedDemon:           return "5 tools in 30 seconds"
        case .resilient:            return "Recover from 3+ errors"
        case .zenMaster:            return "20 positive moods in a row"
        case .teamPlayer:           return "Join a room"
        case .socialButterfly:      return "Send 10 reactions"
        case .statusSetter:         return "Set your status 25 times"
        case .streakThree:          return "3-day coding streak"
        case .streakSeven:          return "7-day coding streak"
        case .streakFourteen:       return "14-day coding streak"
        case .streakThirty:         return "30-day coding streak"
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
        case .fiveSessions:
            return [
                [1,1,1,1,1],
                [1,0,0,0,0],
                [1,1,1,1,0],
                [0,0,0,0,1],
                [1,1,1,1,1],
            ]
        case .tenSessions:
            return [
                [1,0,0,0,1],
                [1,0,1,0,1],
                [1,0,1,0,1],
                [1,0,1,0,1],
                [1,0,1,0,1],
            ]
        case .twentyFiveSessions:
            return [
                [0,1,1,1,0],
                [1,0,0,0,0],
                [0,1,1,1,0],
                [0,0,0,0,1],
                [0,1,1,1,0],
            ]
        case .fiftySessions:
            return [
                [1,1,1,1,1],
                [1,0,0,0,0],
                [1,1,1,1,0],
                [0,0,0,1,0],
                [1,1,1,1,0],
            ]
        case .hundredSessions:
            return [
                [1,0,1,1,1],
                [1,0,1,0,1],
                [1,0,1,0,1],
                [1,0,1,0,1],
                [1,0,1,1,1],
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
        case .centurion:
            return [
                [0,2,2,2,0],
                [2,0,0,0,2],
                [2,0,1,0,2],
                [2,0,0,0,2],
                [0,2,2,2,0],
            ]
        case .dedicated:
            return [
                [0,1,1,1,0],
                [1,2,0,2,1],
                [1,0,2,0,1],
                [1,2,0,2,1],
                [0,1,1,1,0],
            ]
        case .ironclad:
            return [
                [1,1,1,1,1],
                [1,2,2,2,1],
                [1,2,1,2,1],
                [1,2,2,2,1],
                [1,1,1,1,1],
            ]
        case .bugSquasher:
            return [
                [0,1,0,1,0],
                [1,1,1,1,1],
                [1,2,1,2,1],
                [1,1,1,1,1],
                [0,1,0,1,0],
            ]
        case .toolsmith:
            return [
                [0,0,1,0,0],
                [0,1,1,0,0],
                [0,0,1,0,0],
                [0,0,1,0,0],
                [0,1,1,1,0],
            ]
        case .prolific:
            return [
                [1,0,1,0,1],
                [1,0,1,0,1],
                [1,1,1,1,1],
                [0,1,0,1,0],
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
        case .resilient:
            return [
                [0,1,0,1,0],
                [0,0,1,0,0],
                [0,1,2,1,0],
                [1,2,2,2,1],
                [0,1,2,1,0],
            ]
        case .zenMaster:
            return [
                [0,0,2,0,0],
                [0,2,2,2,0],
                [2,2,1,2,2],
                [0,2,2,2,0],
                [0,0,2,0,0],
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
        case .statusSetter:
            return [
                [1,1,1,1,1],
                [1,2,2,2,1],
                [1,1,1,1,1],
                [0,1,0,0,0],
                [0,0,0,0,0],
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
        case .streakFourteen:
            return [
                [2,2,2,2,2],
                [2,1,1,1,2],
                [1,1,2,1,1],
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
        case .firstSession:         return Color(red: 0.3, green: 0.8, blue: 0.4)
        case .fiveSessions:         return Color(red: 0.35, green: 0.75, blue: 0.5)
        case .tenSessions:          return Color(red: 0.3, green: 0.7, blue: 0.9)
        case .twentyFiveSessions:   return Color(red: 0.4, green: 0.5, blue: 0.9)
        case .fiftySessions:        return Color(red: 0.6, green: 0.4, blue: 0.9)
        case .hundredSessions:      return Color(red: 0.7, green: 0.3, blue: 0.8)
        case .marathon:             return Color(red: 0.9, green: 0.7, blue: 0.2)
        case .nightOwl:             return Color(red: 0.4, green: 0.3, blue: 0.7)
        case .earlyBird:            return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .centurion:            return Color(red: 0.3, green: 0.7, blue: 0.5)
        case .dedicated:            return Color(red: 0.2, green: 0.6, blue: 0.7)
        case .ironclad:             return Color(red: 0.5, green: 0.5, blue: 0.6)
        case .bugSquasher:          return Color(red: 0.8, green: 0.2, blue: 0.2)
        case .toolsmith:            return Color(red: 0.7, green: 0.35, blue: 0.2)
        case .prolific:             return Color(red: 0.6, green: 0.5, blue: 0.1)
        case .speedDemon:           return Color(red: 0.0, green: 0.8, blue: 0.9)
        case .resilient:            return Color(red: 0.2, green: 0.8, blue: 0.6)
        case .zenMaster:            return Color(red: 0.5, green: 0.7, blue: 0.9)
        case .teamPlayer:           return Color(red: 0.3, green: 0.6, blue: 0.9)
        case .socialButterfly:      return Color(red: 0.9, green: 0.4, blue: 0.6)
        case .statusSetter:         return Color(red: 0.4, green: 0.7, blue: 0.9)
        case .streakThree:          return Color(red: 1.0, green: 0.5, blue: 0.0)
        case .streakSeven:          return Color(red: 1.0, green: 0.4, blue: 0.0)
        case .streakFourteen:       return Color(red: 1.0, green: 0.35, blue: 0.0)
        case .streakThirty:         return Color(red: 1.0, green: 0.3, blue: 0.0)
        }
    }

    var secondaryColor: Color {
        switch self {
        case .firstSession:         return Color(red: 0.9, green: 1.0, blue: 0.5)
        case .fiveSessions:         return Color(red: 0.7, green: 0.95, blue: 0.6)
        case .tenSessions:          return Color(red: 0.6, green: 0.9, blue: 1.0)
        case .twentyFiveSessions:   return Color(red: 0.65, green: 0.7, blue: 1.0)
        case .fiftySessions:        return Color(red: 0.8, green: 0.6, blue: 1.0)
        case .hundredSessions:      return Color(red: 0.9, green: 0.6, blue: 0.95)
        case .marathon:             return Color(red: 1.0, green: 0.9, blue: 0.5)
        case .nightOwl:             return Color(red: 0.7, green: 0.6, blue: 1.0)
        case .earlyBird:            return Color(red: 1.0, green: 0.85, blue: 0.3)
        case .centurion:            return Color(red: 0.6, green: 0.9, blue: 0.7)
        case .dedicated:            return Color(red: 0.5, green: 0.85, blue: 0.9)
        case .ironclad:             return Color(red: 0.75, green: 0.75, blue: 0.85)
        case .bugSquasher:          return Color(red: 1.0, green: 0.5, blue: 0.4)
        case .toolsmith:            return Color(red: 0.9, green: 0.6, blue: 0.4)
        case .prolific:             return Color(red: 0.9, green: 0.8, blue: 0.3)
        case .speedDemon:           return Color(red: 0.5, green: 1.0, blue: 1.0)
        case .resilient:            return Color(red: 0.5, green: 1.0, blue: 0.8)
        case .zenMaster:            return Color(red: 0.7, green: 0.85, blue: 1.0)
        case .teamPlayer:           return Color(red: 0.6, green: 0.8, blue: 1.0)
        case .socialButterfly:      return Color(red: 1.0, green: 0.7, blue: 0.85)
        case .statusSetter:         return Color(red: 0.6, green: 0.85, blue: 1.0)
        case .streakThree:          return Color(red: 1.0, green: 0.85, blue: 0.2)
        case .streakSeven:          return Color(red: 1.0, green: 0.8, blue: 0.1)
        case .streakFourteen:       return Color(red: 1.0, green: 0.75, blue: 0.15)
        case .streakThirty:         return Color(red: 1.0, green: 0.95, blue: 0.4)
        }
    }
}

/// A single earned achievement record.
struct EarnedAchievement: Codable, Identifiable {
    let achievementId: AchievementId
    let earnedAt: Date

    var id: String { achievementId.rawValue }
}
