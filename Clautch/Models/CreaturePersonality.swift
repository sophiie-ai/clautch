import Foundation

/// Personality traits that emerge from usage patterns over time.
enum PersonalityTrait: String, Codable, CaseIterable, Sendable {
    case curious    // explores many different tools
    case focused    // long uninterrupted sessions
    case social     // active in rooms, sends reactions
    case nocturnal  // codes at night
    case resilient  // recovers from errors well
    case playful    // speed bursts, varied emotions
    case zen        // consistently positive moods

    var displayName: String {
        switch self {
        case .curious:   return "Curious"
        case .focused:   return "Focused"
        case .social:    return "Social"
        case .nocturnal: return "Nocturnal"
        case .resilient: return "Resilient"
        case .playful:   return "Playful"
        case .zen:       return "Zen"
        }
    }

    var emoji: String {
        switch self {
        case .curious:   return "🔍"
        case .focused:   return "🎯"
        case .social:    return "💬"
        case .nocturnal: return "🌙"
        case .resilient: return "💪"
        case .playful:   return "✨"
        case .zen:       return "🧘"
        }
    }

    var description: String {
        switch self {
        case .curious:   return "Loves exploring different tools"
        case .focused:   return "Thrives in long deep-work sessions"
        case .social:    return "Enjoys hanging out with teammates"
        case .nocturnal: return "Most alive when the sun goes down"
        case .resilient: return "Bounces back from errors with ease"
        case .playful:   return "Energetic and full of surprises"
        case .zen:       return "Radiates calm and positivity"
        }
    }
}

/// Emergent personality computed from accumulated usage patterns.
struct CreaturePersonality: Codable, Sendable {
    var curious: Double = 0
    var focused: Double = 0
    var social: Double = 0
    var nocturnal: Double = 0
    var resilient: Double = 0
    var playful: Double = 0
    var zen: Double = 0
    var lastUpdated: Date = .distantPast

    /// Value for a specific trait.
    func value(for trait: PersonalityTrait) -> Double {
        switch trait {
        case .curious:   return curious
        case .focused:   return focused
        case .social:    return social
        case .nocturnal: return nocturnal
        case .resilient: return resilient
        case .playful:   return playful
        case .zen:       return zen
        }
    }

    /// All traits sorted by strength descending.
    var rankedTraits: [(trait: PersonalityTrait, strength: Double)] {
        PersonalityTrait.allCases
            .map { (trait: $0, strength: value(for: $0)) }
            .sorted { $0.strength > $1.strength }
    }

    /// The strongest trait, or nil if all are zero.
    var dominantTrait: PersonalityTrait? {
        let top = rankedTraits.first
        guard let top, top.strength > 0.05 else { return nil }
        return top.trait
    }

    /// The second strongest trait, or nil.
    var secondaryTrait: PersonalityTrait? {
        let ranked = rankedTraits
        guard ranked.count >= 2, ranked[1].strength > 0.05 else { return nil }
        return ranked[1].trait
    }
}
