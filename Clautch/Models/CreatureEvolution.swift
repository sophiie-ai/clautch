import SwiftUI

/// Evolution stage of a creature, determined by cumulative XP.
enum CreatureEvolution: String, Codable, Sendable, Comparable {
    case baby
    case grown
    case elder

    private var order: Int {
        switch self {
        case .baby:  return 0
        case .grown: return 1
        case .elder: return 2
        }
    }

    static func < (lhs: CreatureEvolution, rhs: CreatureEvolution) -> Bool {
        lhs.order < rhs.order
    }

    /// Compute evolution stage from XP total.
    static func from(xp: Int) -> CreatureEvolution {
        if xp >= 500 { return .elder }
        if xp >= 100 { return .grown }
        return .baby
    }

    /// XP required to reach this stage.
    var xpThreshold: Int {
        switch self {
        case .baby:  return 0
        case .grown: return 100
        case .elder: return 500
        }
    }

    /// XP required to reach the next stage (nil if max).
    var nextThreshold: Int? {
        switch self {
        case .baby:  return 100
        case .grown: return 500
        case .elder: return nil
        }
    }

    var displayName: String {
        switch self {
        case .baby:  return "Baby"
        case .grown: return "Grown"
        case .elder: return "Elder"
        }
    }

    /// Glow color for this evolution stage.
    var glowColor: Color {
        switch self {
        case .baby:  return .clear
        case .grown: return Color(red: 0.4, green: 0.8, blue: 1.0)
        case .elder: return Color(red: 1.0, green: 0.85, blue: 0.3)
        }
    }

    /// Glow intensity (radius) for this stage.
    var glowRadius: CGFloat {
        switch self {
        case .baby:  return 0
        case .grown: return 2
        case .elder: return 4
        }
    }
}
