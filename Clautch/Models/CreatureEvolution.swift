import SwiftUI

/// Evolution stage of a creature, determined by cumulative XP.
enum CreatureEvolution: String, Codable, Sendable, Comparable, CaseIterable {
    case baby
    case juvenile
    case grown
    case mature
    case elder
    case ancient

    private var order: Int {
        switch self {
        case .baby:     return 0
        case .juvenile: return 1
        case .grown:    return 2
        case .mature:   return 3
        case .elder:    return 4
        case .ancient:  return 5
        }
    }

    static func < (lhs: CreatureEvolution, rhs: CreatureEvolution) -> Bool {
        lhs.order < rhs.order
    }

    /// Compute evolution stage from XP total.
    static func from(xp: Int) -> CreatureEvolution {
        if xp >= 1000 { return .ancient }
        if xp >= 600  { return .elder }
        if xp >= 350  { return .mature }
        if xp >= 150  { return .grown }
        if xp >= 50   { return .juvenile }
        return .baby
    }

    /// XP required to reach this stage.
    var xpThreshold: Int {
        switch self {
        case .baby:     return 0
        case .juvenile: return 50
        case .grown:    return 150
        case .mature:   return 350
        case .elder:    return 600
        case .ancient:  return 1000
        }
    }

    /// XP required to reach the next stage (nil if max).
    var nextThreshold: Int? {
        switch self {
        case .baby:     return 50
        case .juvenile: return 150
        case .grown:    return 350
        case .mature:   return 600
        case .elder:    return 1000
        case .ancient:  return nil
        }
    }

    var displayName: String {
        switch self {
        case .baby:     return "Baby"
        case .juvenile: return "Juvenile"
        case .grown:    return "Grown"
        case .mature:   return "Mature"
        case .elder:    return "Elder"
        case .ancient:  return "Ancient"
        }
    }

    /// Glow color for this evolution stage.
    var glowColor: Color {
        switch self {
        case .baby:     return .clear
        case .juvenile: return Color(red: 0.4, green: 0.9, blue: 0.5)
        case .grown:    return Color(red: 0.4, green: 0.8, blue: 1.0)
        case .mature:   return Color(red: 0.7, green: 0.4, blue: 1.0)
        case .elder:    return Color(red: 1.0, green: 0.85, blue: 0.3)
        case .ancient:  return Color(red: 0.95, green: 0.95, blue: 1.0)
        }
    }

    /// Glow intensity (radius) for this stage.
    var glowRadius: CGFloat {
        switch self {
        case .baby:     return 0
        case .juvenile: return 1
        case .grown:    return 2
        case .mature:   return 3
        case .elder:    return 4
        case .ancient:  return 5
        }
    }
}
