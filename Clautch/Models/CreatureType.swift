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

/// Accessories rendered as pixel overlays above or on the creature.
enum CreatureAccessory: String, CaseIterable, Codable, Identifiable, Sendable {
    case none
    case topHat
    case crown
    case bow
    case glasses
    case hardhat
    case halo

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none:     return "None"
        case .topHat:   return "Top Hat"
        case .crown:    return "Crown"
        case .bow:      return "Bow"
        case .glasses:  return "Glasses"
        case .hardhat:  return "Hard Hat"
        case .halo:     return "Halo"
        }
    }

    var emoji: String {
        switch self {
        case .none:     return "❌"
        case .topHat:   return "🎩"
        case .crown:    return "👑"
        case .bow:      return "🎀"
        case .glasses:  return "🤓"
        case .hardhat:  return "⛑️"
        case .halo:     return "😇"
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
        }
    }

    /// Primary color for pixel type 6.
    var primaryColor: Color {
        switch self {
        case .none:     return .clear
        case .topHat:   return Color(red: 0.2, green: 0.2, blue: 0.2)
        case .crown:    return Color(red: 1.0, green: 0.85, blue: 0.1)
        case .bow:      return Color(red: 1.0, green: 0.3, blue: 0.5)
        case .glasses:  return Color(red: 0.3, green: 0.3, blue: 0.3)
        case .hardhat:  return Color(red: 1.0, green: 0.8, blue: 0.0)
        case .halo:     return Color(red: 1.0, green: 1.0, blue: 0.7)
        }
    }

    /// Secondary color for pixel type 7.
    var secondaryColor: Color {
        switch self {
        case .none:     return .clear
        case .topHat:   return Color(red: 0.35, green: 0.35, blue: 0.35)
        case .crown:    return Color(red: 1.0, green: 0.4, blue: 0.3)
        case .bow:      return Color(red: 1.0, green: 0.5, blue: 0.7)
        case .glasses:  return Color(red: 0.5, green: 0.8, blue: 1.0)
        case .hardhat:  return Color(red: 1.0, green: 0.6, blue: 0.0)
        case .halo:     return Color(red: 1.0, green: 1.0, blue: 0.9)
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
