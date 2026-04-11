import SwiftUI

// MARK: - Creature Type

/// The six creature types a user can choose from.
enum CreatureType: String, CaseIterable, Codable, Identifiable, Sendable {
    case ghost
    case cat
    case robot
    case mushroom
    case slime
    case owl

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ghost:    return "Ghost"
        case .cat:      return "Cat"
        case .robot:    return "Robot"
        case .mushroom: return "Mushroom"
        case .slime:    return "Slime"
        case .owl:      return "Owl"
        }
    }

    /// One-line personality hint shown during onboarding.
    var personalityHint: String {
        switch self {
        case .ghost:    return "Mysterious phaser"
        case .cat:      return "Curious groomer"
        case .robot:    return "Precise thinker"
        case .mushroom: return "Chill bouncer"
        case .slime:    return "Playful wobbler"
        case .owl:      return "Wise observer"
        }
    }

    /// Default body color (before user tint).
    var baseColor: Color {
        switch self {
        case .ghost:    return .white
        case .cat:      return Color(red: 1.0, green: 0.7, blue: 0.4)
        case .robot:    return Color(red: 0.6, green: 0.7, blue: 0.8)
        case .mushroom: return Color(red: 0.9, green: 0.3, blue: 0.3)
        case .slime:    return Color(red: 0.3, green: 0.9, blue: 0.5)
        case .owl:      return Color(red: 0.6, green: 0.45, blue: 0.3)
        }
    }

    /// Accent color for secondary pixels (pixel type 4).
    var accentColor: Color {
        switch self {
        case .ghost:    return Color(white: 0.85)
        case .cat:      return Color(red: 1.0, green: 0.85, blue: 0.6)
        case .robot:    return Color(red: 0.4, green: 0.9, blue: 0.4)
        case .mushroom: return Color(red: 1.0, green: 0.95, blue: 0.8)
        case .slime:    return Color(red: 0.2, green: 0.7, blue: 0.4)
        case .owl:      return Color(red: 0.85, green: 0.75, blue: 0.55)
        }
    }

    // MARK: - Pixel Art

    /// Two-frame pixel art. Each frame is an 8×8 grid.
    /// Pixel codes: 0=clear, 1=body, 2=eye, 3=mouth, 4=accent, 5=highlight
    var frames: [[[Int]]] {
        switch self {
        case .ghost:    return Self.ghostFrames
        case .cat:      return Self.catFrames
        case .robot:    return Self.robotFrames
        case .mushroom: return Self.mushroomFrames
        case .slime:    return Self.slimeFrames
        case .owl:      return Self.owlFrames
        }
    }

    /// Walk animation frames — legs in stepping positions.
    var walkFrames: [[[Int]]] {
        switch self {
        case .ghost:    return Self.ghostWalkFrames
        case .cat:      return Self.catWalkFrames
        case .robot:    return Self.robotWalkFrames
        case .mushroom: return Self.mushroomWalkFrames
        case .slime:    return Self.slimeWalkFrames
        case .owl:      return Self.owlWalkFrames
        }
    }

    // MARK: - Ghost

    private static let ghostFrames: [[[Int]]] = [
        parse("""
        ..1111..
        .111111.
        11211211
        11211211
        11133111
        11111111
        11111111
        1.1.1.1.
        """),
        parse("""
        ..1111..
        .111111.
        11211211
        11211211
        11133111
        11111111
        11111111
        .1.1.1.1
        """),
    ]

    // MARK: - Cat

    private static let catFrames: [[[Int]]] = [
        parse("""
        1......1
        11....11
        11111111
        11211211
        11111111
        11133111
        .1111111
        ..1..1..
        """),
        parse("""
        1......1
        11....11
        11111111
        11211211
        11111111
        11133111
        1111111.
        ..1..1..
        """),
    ]

    // MARK: - Robot

    private static let robotFrames: [[[Int]]] = [
        parse("""
        ...44...
        .111111.
        .121121.
        .111111.
        11133111
        .114411.
        .1.11.1.
        .1....1.
        """),
        parse("""
        ...44...
        .111111.
        .121121.
        .111111.
        11133111
        .114411.
        .1.11.1.
        1......1
        """),
    ]

    // MARK: - Mushroom

    private static let mushroomFrames: [[[Int]]] = [
        parse("""
        ..1111..
        .115511.
        11155111
        11111111
        ..4444..
        ..4224..
        ..4334..
        ...44...
        """),
        parse("""
        ..1111..
        .115511.
        11155111
        11111111
        ..4444..
        ..4224..
        ..4334..
        ..4..4..
        """),
    ]

    // MARK: - Slime

    private static let slimeFrames: [[[Int]]] = [
        parse("""
        ........
        ...11...
        ..1111..
        .112211.
        .111111.
        11133111
        11111111
        .111111.
        """),
        parse("""
        ........
        ..1111..
        .111111.
        .112211.
        .111111.
        .113311.
        11111111
        .111111.
        """),
    ]

    // MARK: - Owl

    private static let owlFrames: [[[Int]]] = [
        parse("""
        .1....1.
        11111111
        12212211
        12212211
        11133111
        .111111.
        .1.11.1.
        ...11...
        """),
        parse("""
        1......1
        11111111
        12212211
        12212211
        11133111
        .111111.
        .1.11.1.
        ...11...
        """),
    ]

    // MARK: - Walk Frames

    private static let ghostWalkFrames: [[[Int]]] = [
        parse("""
        ..1111..
        .111111.
        11211211
        11211211
        11133111
        11111111
        .111111.
        1......1
        """),
        parse("""
        ..1111..
        .111111.
        11211211
        11211211
        11133111
        11111111
        .111111.
        .1....1.
        """),
    ]

    private static let catWalkFrames: [[[Int]]] = [
        parse("""
        1......1
        11....11
        11111111
        11211211
        11111111
        11133111
        .1111111
        .1....1.
        """),
        parse("""
        1......1
        11....11
        11111111
        11211211
        11111111
        11133111
        1111111.
        .1....1.
        """),
    ]

    private static let robotWalkFrames: [[[Int]]] = [
        parse("""
        ...44...
        .111111.
        .121121.
        .111111.
        11133111
        .114411.
        .1.11.1.
        1......1
        """),
        parse("""
        ...44...
        .111111.
        .121121.
        .111111.
        11133111
        .114411.
        .1.11.1.
        .1....1.
        """),
    ]

    private static let mushroomWalkFrames: [[[Int]]] = [
        parse("""
        ..1111..
        .115511.
        11155111
        11111111
        ..4444..
        ..4224..
        ..4334..
        .4....4.
        """),
        parse("""
        ..1111..
        .115511.
        11155111
        11111111
        ..4444..
        ..4224..
        ..4334..
        4......4
        """),
    ]

    private static let slimeWalkFrames: [[[Int]]] = [
        parse("""
        ........
        ..1111..
        .111111.
        .112211.
        .111111.
        .113311.
        .1111111
        ..11111.
        """),
        parse("""
        ........
        ..1111..
        .111111.
        .112211.
        .111111.
        .113311.
        1111111.
        .11111..
        """),
    ]

    private static let owlWalkFrames: [[[Int]]] = [
        parse("""
        1......1
        11111111
        12212211
        12212211
        11133111
        .111111.
        .1.11.1.
        ..1..1..
        """),
        parse("""
        .1....1.
        11111111
        12212211
        12212211
        11133111
        .111111.
        .1.11.1.
        .1....1.
        """),
    ]

    // MARK: - Parser

    /// Parse a multiline string into an 8×8 grid of pixel codes.
    private static func parse(_ art: String) -> [[Int]] {
        art.split(separator: "\n").map { line in
            line.map { ch in
                switch ch {
                case ".": return 0
                case "1": return 1
                case "2": return 2
                case "3": return 3
                case "4": return 4
                case "5": return 5
                default:  return 0
                }
            }
        }
    }
}

// MARK: - Creature Color Preset

/// Preset color tints the user can pick.
enum CreatureColorPreset: String, CaseIterable, Codable, Identifiable, Sendable {
    case none
    case sky
    case rose
    case mint
    case lavender
    case peach
    case lemon
    case coral

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    /// The color used to tint body pixels (blended with the creature's base color).
    var tintColor: Color? {
        switch self {
        case .none:     return nil
        case .sky:      return Color(red: 0.5, green: 0.8, blue: 1.0)
        case .rose:     return Color(red: 1.0, green: 0.5, blue: 0.7)
        case .mint:     return Color(red: 0.5, green: 1.0, blue: 0.8)
        case .lavender: return Color(red: 0.7, green: 0.5, blue: 1.0)
        case .peach:    return Color(red: 1.0, green: 0.7, blue: 0.5)
        case .lemon:    return Color(red: 1.0, green: 1.0, blue: 0.5)
        case .coral:    return Color(red: 1.0, green: 0.5, blue: 0.5)
        }
    }

    /// Swatch color for the picker (same as tint, or white for "none").
    var swatchColor: Color {
        tintColor ?? .white
    }
}

// MARK: - Creature Accessory

// MARK: - Accessory Unlock Requirement

/// Defines what a player needs to unlock an accessory.
enum AccessoryRequirement: Sendable {
    case free
    case achievement(AchievementId)
    case streak(Int)
    case xp(Int)
    case prestige(Int)

    var hintText: String {
        switch self {
        case .free:
            return "Free"
        case .achievement(let id):
            return id.title
        case .streak(let days):
            return "\(days)-day streak"
        case .xp(let amount):
            return "\(amount) XP"
        case .prestige(let level):
            return "Prestige \(level)"
        }
    }
}

/// Accessories rendered as pixel overlays above or on the creature.
enum CreatureAccessory: String, CaseIterable, Codable, Identifiable, Sendable {
    case none
    case topHat
    case crown
    case bow
    case glasses
    case hardhat
    case halo
    case scarf
    case headphones
    case wizardHat
    case flowerCrown
    case bandana
    case antlers
    case partyHat
    case monocle
    // Prestige accessories
    case starAura
    case phoenixCrest
    case celestialRing

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none:          return "None"
        case .topHat:        return "Top Hat"
        case .crown:         return "Crown"
        case .bow:           return "Bow"
        case .glasses:       return "Glasses"
        case .hardhat:       return "Hard Hat"
        case .halo:          return "Halo"
        case .scarf:         return "Scarf"
        case .headphones:    return "Headphones"
        case .wizardHat:     return "Wizard Hat"
        case .flowerCrown:   return "Flower Crown"
        case .bandana:       return "Bandana"
        case .antlers:       return "Antlers"
        case .partyHat:      return "Party Hat"
        case .monocle:       return "Monocle"
        case .starAura:      return "Star Aura"
        case .phoenixCrest:  return "Phoenix Crest"
        case .celestialRing: return "Celestial Ring"
        }
    }

    var emoji: String {
        switch self {
        case .none:          return "❌"
        case .topHat:        return "🎩"
        case .crown:         return "👑"
        case .bow:           return "🎀"
        case .glasses:       return "🤓"
        case .hardhat:       return "⛑️"
        case .halo:          return "😇"
        case .scarf:         return "🧣"
        case .headphones:    return "🎧"
        case .wizardHat:     return "🧙"
        case .flowerCrown:   return "🌸"
        case .bandana:       return "🏴"
        case .antlers:       return "🦌"
        case .partyHat:      return "🥳"
        case .monocle:       return "🧐"
        case .starAura:      return "⭐"
        case .phoenixCrest:  return "🔥"
        case .celestialRing: return "💫"
        }
    }

    var unlockRequirement: AccessoryRequirement {
        switch self {
        case .none, .bow, .glasses:     return .free
        case .topHat:                   return .achievement(.firstSession)
        case .scarf:                    return .streak(3)
        case .partyHat:                 return .achievement(.teamPlayer)
        case .headphones:               return .achievement(.marathon)
        case .hardhat:                  return .achievement(.bugSquasher)
        case .flowerCrown:              return .achievement(.socialButterfly)
        case .bandana:                  return .achievement(.speedDemon)
        case .monocle:                  return .achievement(.nightOwl)
        case .antlers:                  return .streak(7)
        case .crown:                    return .achievement(.fiftySessions)
        case .halo:                     return .streak(30)
        case .wizardHat:                return .xp(500)
        case .starAura:                 return .prestige(1)
        case .phoenixCrest:             return .prestige(2)
        case .celestialRing:            return .prestige(3)
        }
    }

    /// 4×3 pixel art overlay. Rendered at top of creature.
    /// Pixel codes: 0=clear, 6=accessory primary, 7=accessory secondary
    var pixels: [[Int]]? {
        switch self {
        case .none: return nil
        case .topHat: return Self.parse("""
            .66.
            .66.
            6666
            """)
        case .crown: return Self.parse("""
            7.7.
            7676
            6666
            """)
        case .bow: return Self.parse("""
            ....
            7667
            .66.
            """)
        case .glasses: return Self.parse("""
            ....
            6.6.
            6767
            """)
        case .hardhat: return Self.parse("""
            .66.
            6776
            6666
            """)
        case .halo: return Self.parse("""
            .77.
            7..7
            ....
            """)
        case .scarf: return Self.parse("""
            ....
            6776
            .67.
            """)
        case .headphones: return Self.parse("""
            6..6
            6776
            ....
            """)
        case .wizardHat: return Self.parse("""
            .7..
            .66.
            6666
            """)
        case .flowerCrown: return Self.parse("""
            7.7.
            6767
            ....
            """)
        case .bandana: return Self.parse("""
            ....
            6776
            6..6
            """)
        case .antlers: return Self.parse("""
            7..7
            7676
            .66.
            """)
        case .partyHat: return Self.parse("""
            ..7.
            .66.
            6666
            """)
        case .monocle: return Self.parse("""
            ....
            ..6.
            .676
            """)
        case .starAura: return Self.parse("""
            .77.
            7667
            .77.
            """)
        case .phoenixCrest: return Self.parse("""
            .67.
            6776
            .66.
            """)
        case .celestialRing: return Self.parse("""
            7667
            6..6
            7667
            """)
        }
    }

    /// Primary color for pixel type 6.
    var primaryColor: Color {
        switch self {
        case .none:          return .clear
        case .topHat:        return Color(red: 0.2, green: 0.2, blue: 0.2)
        case .crown:         return Color(red: 1.0, green: 0.85, blue: 0.1)
        case .bow:           return Color(red: 1.0, green: 0.3, blue: 0.5)
        case .glasses:       return Color(red: 0.3, green: 0.3, blue: 0.3)
        case .hardhat:       return Color(red: 1.0, green: 0.8, blue: 0.0)
        case .halo:          return Color(red: 1.0, green: 1.0, blue: 0.7)
        case .scarf:         return Color(red: 0.8, green: 0.2, blue: 0.2)
        case .headphones:    return Color(red: 0.25, green: 0.25, blue: 0.3)
        case .wizardHat:     return Color(red: 0.3, green: 0.2, blue: 0.6)
        case .flowerCrown:   return Color(red: 0.3, green: 0.7, blue: 0.3)
        case .bandana:       return Color(red: 0.15, green: 0.15, blue: 0.15)
        case .antlers:       return Color(red: 0.55, green: 0.35, blue: 0.2)
        case .partyHat:      return Color(red: 0.2, green: 0.6, blue: 0.9)
        case .monocle:       return Color(red: 0.7, green: 0.6, blue: 0.3)
        case .starAura:      return Color(red: 1.0, green: 0.85, blue: 0.0)
        case .phoenixCrest:  return Color(red: 0.9, green: 0.2, blue: 0.1)
        case .celestialRing: return Color(red: 0.6, green: 0.4, blue: 1.0)
        }
    }

    /// Secondary color for pixel type 7.
    var secondaryColor: Color {
        switch self {
        case .none:          return .clear
        case .topHat:        return Color(red: 0.35, green: 0.35, blue: 0.35)
        case .crown:         return Color(red: 1.0, green: 0.4, blue: 0.3)
        case .bow:           return Color(red: 1.0, green: 0.5, blue: 0.7)
        case .glasses:       return Color(red: 0.5, green: 0.8, blue: 1.0)
        case .hardhat:       return Color(red: 1.0, green: 0.6, blue: 0.0)
        case .halo:          return Color(red: 1.0, green: 1.0, blue: 0.9)
        case .scarf:         return Color(red: 0.9, green: 0.85, blue: 0.8)
        case .headphones:    return Color(red: 0.5, green: 0.8, blue: 1.0)
        case .wizardHat:     return Color(red: 0.9, green: 0.8, blue: 0.2)
        case .flowerCrown:   return Color(red: 1.0, green: 0.5, blue: 0.7)
        case .bandana:       return Color(red: 0.6, green: 0.1, blue: 0.1)
        case .antlers:       return Color(red: 0.75, green: 0.55, blue: 0.35)
        case .partyHat:      return Color(red: 1.0, green: 0.9, blue: 0.2)
        case .monocle:       return Color(red: 0.85, green: 0.75, blue: 0.5)
        case .starAura:      return Color(red: 1.0, green: 1.0, blue: 0.6)
        case .phoenixCrest:  return Color(red: 1.0, green: 0.5, blue: 0.2)
        case .celestialRing: return Color(red: 0.8, green: 0.7, blue: 1.0)
        }
    }

    private static func parse(_ art: String) -> [[Int]] {
        art.split(separator: "\n").map { line in
            line.map { ch in
                switch ch {
                case "6": return 6
                case "7": return 7
                default:  return 0
                }
            }
        }
    }
}
