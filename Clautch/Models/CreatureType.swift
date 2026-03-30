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
