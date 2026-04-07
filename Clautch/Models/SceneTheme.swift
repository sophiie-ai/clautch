import SwiftUI

/// Preset background environments for the notch panel scene.
enum SceneTheme: String, CaseIterable, Codable, Identifiable, Sendable {
    case meadow
    case moon
    case island
    case forest
    case alien
    case sakura
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .meadow: return "Meadow"
        case .moon:   return "Moon"
        case .island: return "Island"
        case .forest: return "Forest"
        case .alien:  return "Alien"
        case .sakura: return "Sakura"
        case .custom: return "Custom"
        }
    }

    var emoji: String {
        switch self {
        case .meadow: return "\u{1F33F}" // herb
        case .moon:   return "\u{1F311}" // new moon
        case .island: return "\u{1F334}" // palm tree
        case .forest: return "\u{1F332}" // evergreen
        case .alien:  return "\u{1F47E}" // alien
        case .sakura: return "\u{1F338}" // cherry blossom
        case .custom: return "\u{1F5BC}" // framed picture
        }
    }

    // MARK: - Sky

    /// Sky gradient colors for a given fractional hour (0-24).
    func skyColors(hour: Double) -> (top: Color, bottom: Color) {
        switch self {
        case .meadow:
            return Self.meadowSky(hour: hour)
        case .moon:
            return (
                Color(red: 0.02, green: 0.02, blue: 0.08),
                Color(red: 0.06, green: 0.06, blue: 0.15)
            )
        case .island:
            let b = Self.dayBrightness(hour: hour)
            return (
                Color(red: 0.15 + 0.35 * b, green: 0.55 + 0.25 * b, blue: 0.8 + 0.15 * b),
                Color(red: 0.35 + 0.4 * b, green: 0.7 + 0.2 * b, blue: 0.85 + 0.1 * b)
            )
        case .forest:
            // Dark sky visible through canopy — deep blue at night, muted blue-grey by day
            let b = Self.dayBrightness(hour: hour)
            return (
                Color(red: 0.06 + 0.12 * b, green: 0.08 + 0.18 * b, blue: 0.15 + 0.3 * b),
                Color(red: 0.1 + 0.15 * b, green: 0.14 + 0.22 * b, blue: 0.2 + 0.3 * b)
            )
        case .alien:
            // Green-tinted alien sky (original forest)
            let b = Self.dayBrightness(hour: hour)
            return (
                Color(red: 0.05 + 0.1 * b, green: 0.12 + 0.15 * b, blue: 0.08 + 0.08 * b),
                Color(red: 0.08 + 0.12 * b, green: 0.18 + 0.2 * b, blue: 0.1 + 0.1 * b)
            )
        case .sakura:
            let b = Self.dayBrightness(hour: hour)
            return (
                Color(red: 0.85 + 0.1 * b, green: 0.75 + 0.1 * b, blue: 0.8 + 0.1 * b),
                Color(red: 0.92 + 0.05 * b, green: 0.85 + 0.08 * b, blue: 0.88 + 0.06 * b)
            )
        case .custom:
            // Transparent — image is drawn underneath
            return (Color.clear, Color.clear)
        }
    }

    /// Number of stars to render for a given fractional hour.
    func starCount(hour: Double) -> Int {
        switch self {
        case .meadow:
            return Self.meadowStarCount(hour: hour)
        case .moon:
            return 20  // always dense stars
        case .island:
            // Tropical night sky
            let night = 1.0 - Self.dayBrightness(hour: hour)
            return Int(night * 12)
        case .forest:
            // Few stars peeking through canopy at night
            let night = 1.0 - Self.dayBrightness(hour: hour)
            return Int(night * 4)
        case .alien:
            let night = 1.0 - Self.dayBrightness(hour: hour)
            return Int(night * 6)
        case .sakura:
            return 0   // bright daytime feel
        case .custom:
            return 0
        }
    }

    // MARK: - Ground

    var groundColors: (surface: Color, base: Color) {
        switch self {
        case .meadow:
            let season = Season.current
            return (season.grassColor.blade, season.grassColor.ground)
        case .moon:
            return (
                Color(red: 0.45, green: 0.43, blue: 0.4),
                Color(red: 0.25, green: 0.24, blue: 0.22)
            )
        case .island:
            return (
                Color(red: 0.85, green: 0.78, blue: 0.6),   // warm sand
                Color(red: 0.65, green: 0.58, blue: 0.42)
            )
        case .forest:
            return (
                Color(red: 0.25, green: 0.2, blue: 0.12),  // earthy brown
                Color(red: 0.15, green: 0.12, blue: 0.08)
            )
        case .alien:
            return (
                Color(red: 0.2, green: 0.35, blue: 0.15),  // mossy green
                Color(red: 0.12, green: 0.22, blue: 0.1)
            )
        case .sakura:
            return (
                Color(red: 0.7, green: 0.65, blue: 0.6),   // stone path
                Color(red: 0.5, green: 0.47, blue: 0.43)
            )
        case .custom:
            return (
                Color(red: 0.15, green: 0.15, blue: 0.15),
                Color(red: 0.1, green: 0.1, blue: 0.1)
            )
        }
    }

    // MARK: - Ground Detail

    // MARK: - Particles

    var particleCount: Int {
        switch self {
        case .meadow: return Season.current.particleCount
        case .moon:   return 8
        case .island: return 6
        case .forest: return 12
        case .alien:  return 10
        case .sakura: return 14
        case .custom: return 0
        }
    }

    // MARK: - Helpers

    /// 0.0 at midnight, 1.0 at noon — smooth sine curve.
    private static func dayBrightness(hour: Double) -> Double {
        let clamped = hour.truncatingRemainder(dividingBy: 24)
        // Peak at noon (12), trough at midnight (0/24)
        return max(0, sin((clamped - 6) / 24 * .pi * 2) * 0.5 + 0.5)
    }

    /// Meadow sky uses the existing time-of-day interpolation with seasonal tint.
    private static func meadowSky(hour: Double) -> (top: Color, bottom: Color) {
        let t = hour

        let keys: [(h: Double, tr: Double, tg: Double, tb: Double, br: Double, bg: Double, bb: Double)] = [
            (0,  0.08, 0.10, 0.25, 0.12, 0.18, 0.35),
            (6,  0.08, 0.10, 0.25, 0.12, 0.18, 0.35),
            (7,  0.45, 0.30, 0.40, 0.75, 0.45, 0.30),
            (8,  0.20, 0.45, 0.75, 0.40, 0.65, 0.85),
            (17, 0.20, 0.45, 0.75, 0.40, 0.65, 0.85),
            (18, 0.35, 0.20, 0.45, 0.70, 0.35, 0.30),
            (19, 0.12, 0.12, 0.30, 0.15, 0.20, 0.35),
            (24, 0.08, 0.10, 0.25, 0.12, 0.18, 0.35),
        ]

        var lo = keys[0], hi = keys[1]
        for i in 0..<(keys.count - 1) {
            if t >= keys[i].h && t < keys[i + 1].h {
                lo = keys[i]; hi = keys[i + 1]; break
            }
        }
        let span = hi.h - lo.h
        let f = span > 0 ? (t - lo.h) / span : 0

        let tint = Season.current.skyTint
        func clamp(_ v: Double) -> Double { min(1, max(0, v)) }

        let top = Color(
            red: clamp(lo.tr + (hi.tr - lo.tr) * f + tint.r),
            green: clamp(lo.tg + (hi.tg - lo.tg) * f + tint.g),
            blue: clamp(lo.tb + (hi.tb - lo.tb) * f + tint.b)
        )
        let bot = Color(
            red: clamp(lo.br + (hi.br - lo.br) * f + tint.r),
            green: clamp(lo.bg + (hi.bg - lo.bg) * f + tint.g),
            blue: clamp(lo.bb + (hi.bb - lo.bb) * f + tint.b)
        )
        return (top, bot)
    }

    private static func meadowStarCount(hour: Double) -> Int {
        let t = hour
        let keys: [(h: Double, s: Double)] = [
            (0, 14), (6, 14), (7, 3), (8, 0), (17, 0), (18, 4), (19, 10), (24, 14),
        ]
        var lo = keys[0], hi = keys[1]
        for i in 0..<(keys.count - 1) {
            if t >= keys[i].h && t < keys[i + 1].h {
                lo = keys[i]; hi = keys[i + 1]; break
            }
        }
        let span = hi.h - lo.h
        let f = span > 0 ? (t - lo.h) / span : 0
        let base = Int((lo.s + (hi.s - lo.s) * f).rounded())
        let adj = Season.current == .winter ? 3 : (Season.current == .summer ? -2 : 0)
        return max(0, base + adj)
    }
}

// MARK: - Particle Drawing

extension SceneTheme {
    /// Draw a single particle for this theme.
    /// `hour` is the current fractional hour (0-24), pre-computed once per frame.
    func drawParticle(
        ctx: inout GraphicsContext, index: Int, seed: Double, time: Double,
        left: CGFloat, width: CGFloat, skyTop: CGFloat, skyBottom: CGFloat,
        hour: Double
    ) {
        let skyH = skyBottom - skyTop
        guard skyH > 4 else { return }

        switch self {
        case .meadow:
            // Pass real star count so summer fireflies gate correctly on nighttime
            let stars = Self.meadowStarCount(hour: hour)
            GrassIslandView.drawWeatherParticle(
                ctx: &ctx, season: Season.current, index: index, seed: seed, time: time,
                left: left, width: width, skyTop: skyTop, skyBottom: skyBottom,
                starCount: stars
            )

        case .moon:
            // Slow-floating dust motes
            let cycle = 12.0
            let phase = (time + seed).truncatingRemainder(dividingBy: cycle) / cycle
            let baseX = left + CGFloat((seed * 0.618).truncatingRemainder(dividingBy: 1.0)) * width
            let drift = CGFloat(sin(time * 0.3 + seed)) * 5
            let x = baseX + drift
            let y = skyTop + CGFloat(phase) * skyH
            let alpha = 0.2 + 0.3 * (1.0 - abs(phase - 0.5) * 1.5)
            let sz: CGFloat = index % 3 == 0 ? 1.5 : 1
            ctx.fill(
                Path(CGRect(x: x, y: y, width: sz, height: sz)),
                with: .color(Color(red: 0.7, green: 0.65, blue: 0.5).opacity(min(1, alpha)))
            )

        case .island:
            // Drifting clouds / sea breeze wisps
            let cycle = 15.0
            let phase = (time * 0.5 + seed).truncatingRemainder(dividingBy: cycle) / cycle
            let baseY = skyTop + CGFloat((seed * 0.382).truncatingRemainder(dividingBy: 1.0)) * skyH * 0.6
            let x = left + CGFloat(phase) * (width + 20) - 10  // drift right across sky
            let y = baseY + CGFloat(sin(time * 0.3 + seed)) * 3
            let alpha = 0.15 + 0.15 * (1.0 - abs(phase - 0.5) * 1.5)
            let w: CGFloat = index % 3 == 0 ? 6 : 4
            ctx.fill(
                Path(CGRect(x: x, y: y, width: w, height: 1.5)),
                with: .color(Color.white.opacity(min(1, alpha)))
            )
            ctx.fill(
                Path(CGRect(x: x + 1, y: y + 1, width: w - 2, height: 1)),
                with: .color(Color.white.opacity(min(1, alpha) * 0.6))
            )

        case .alien:
            // Alien reuses original forest particles (pine needles + fireflies)
            let isAlienNight = SceneTheme.dayBrightness(hour: hour) < 0.3
            if isAlienNight && index % 2 == 0 {
                let cx = left + CGFloat((seed * 0.618).truncatingRemainder(dividingBy: 1.0)) * width
                let baseY = skyTop + CGFloat((seed * 0.382).truncatingRemainder(dividingBy: 1.0)) * skyH
                let x = cx + CGFloat(sin(time * 0.7 + seed)) * 6
                let y = baseY + CGFloat(cos(time * 0.5 + seed * 1.3)) * 4
                let pulse = 0.2 + 0.8 * abs(sin(time * 1.8 + seed))
                ctx.fill(
                    Path(CGRect(x: x - 0.5, y: y - 0.5, width: 2, height: 2)),
                    with: .color(Color(red: 0.4, green: 1.0, blue: 0.5).opacity(pulse * 0.15))
                )
                ctx.fill(
                    Path(CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(Color(red: 0.5, green: 1.0, blue: 0.6).opacity(pulse * 0.7))
                )
            } else {
                let cycle = 5.0
                let phase = (time + seed).truncatingRemainder(dividingBy: cycle) / cycle
                let baseX = left + CGFloat((seed * 0.618).truncatingRemainder(dividingBy: 1.0)) * width
                let drift = CGFloat(sin(time * 0.6 + seed * 2.0)) * 4
                let x = baseX + drift
                let y = skyTop + CGFloat(phase) * skyH
                let alpha = 0.5 * (1.0 - abs(phase - 0.5) * 1.5)
                let color = Color(red: 0.15, green: 0.4, blue: 0.12)
                ctx.fill(
                    Path(CGRect(x: x, y: y, width: 2, height: 0.8)),
                    with: .color(color.opacity(min(1, alpha)))
                )
            }

        case .forest:
            // Falling leaves + fireflies at night
            let isNight = SceneTheme.dayBrightness(hour: hour) < 0.3
            if isNight && index % 2 == 0 {
                // Firefly
                let cx = left + CGFloat((seed * 0.618).truncatingRemainder(dividingBy: 1.0)) * width
                let baseY = skyTop + CGFloat((seed * 0.382).truncatingRemainder(dividingBy: 1.0)) * skyH
                let x = cx + CGFloat(sin(time * 0.7 + seed)) * 6
                let y = baseY + CGFloat(cos(time * 0.5 + seed * 1.3)) * 4
                let pulse = 0.2 + 0.8 * abs(sin(time * 1.8 + seed))
                ctx.fill(
                    Path(CGRect(x: x - 0.5, y: y - 0.5, width: 2, height: 2)),
                    with: .color(Color(red: 0.8, green: 1.0, blue: 0.4).opacity(pulse * 0.15))
                )
                ctx.fill(
                    Path(CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(Color(red: 0.9, green: 1.0, blue: 0.5).opacity(pulse * 0.7))
                )
            } else {
                // Pine needle
                let cycle = 5.0
                let phase = (time + seed).truncatingRemainder(dividingBy: cycle) / cycle
                let baseX = left + CGFloat((seed * 0.618).truncatingRemainder(dividingBy: 1.0)) * width
                let drift = CGFloat(sin(time * 0.6 + seed * 2.0)) * 4
                let x = baseX + drift
                let y = skyTop + CGFloat(phase) * skyH
                let alpha = 0.5 * (1.0 - abs(phase - 0.5) * 1.5)
                let colors: [Color] = [
                    Color(red: 0.2, green: 0.4, blue: 0.15),
                    Color(red: 0.3, green: 0.45, blue: 0.2),
                    Color(red: 0.15, green: 0.35, blue: 0.1),
                ]
                let color = colors[index % colors.count]
                ctx.fill(
                    Path(CGRect(x: x, y: y, width: 2, height: 0.8)),
                    with: .color(color.opacity(min(1, alpha)))
                )
            }

        case .sakura:
            // Cherry blossom petals — always falling
            let cycle = 8.0
            let phase = (time + seed).truncatingRemainder(dividingBy: cycle) / cycle
            let x = left + CGFloat((seed * 0.618).truncatingRemainder(dividingBy: 1.0)) * width
                + CGFloat(sin((time + seed) * 1.2)) * 6
            let y = skyTop + CGFloat(phase) * skyH
            let alpha = 1.0 - abs(phase - 0.5) * 0.6
            let petalColors: [Color] = [
                Color(red: 1.0, green: 0.7, blue: 0.8),
                Color(red: 1.0, green: 0.8, blue: 0.85),
                Color(red: 1.0, green: 0.6, blue: 0.75),
                Color(red: 0.95, green: 0.75, blue: 0.85),
            ]
            let color = petalColors[index % petalColors.count]
            let tumble = sin(time * 2.5 + seed)
            let w: CGFloat = tumble > 0 ? 2.5 : 1.5
            let h: CGFloat = tumble > 0 ? 1.5 : 2.5
            ctx.fill(
                Path(CGRect(x: x, y: y, width: w, height: h)),
                with: .color(color.opacity(alpha * 0.75))
            )

        case .custom:
            break  // no particles — user image is the background
        }
    }

    /// Draw a palm tree at a given position.
    private static func drawPalmTree(
        ctx: inout GraphicsContext, left: CGFloat, width: CGFloat, grassY: CGFloat,
        xFrac: CGFloat, height: CGFloat, curve: CGFloat, alpha: Double
    ) {
        let palmX = left + width * xFrac
        let trunkBase = grassY
        let trunkTop = grassY - height

        // Trunk (slightly curved)
        for i in 0..<10 {
            let t = CGFloat(i) / 10.0
            let x = palmX + sin(t * curve) * 2
            let y = trunkBase - t * (trunkBase - trunkTop)
            let w: CGFloat = 2.5 - t * 0.8
            ctx.fill(
                Path(CGRect(x: x - w / 2, y: y - 1, width: w, height: 2.5)),
                with: .color(Color(red: 0.5, green: 0.35, blue: 0.2).opacity(alpha))
            )
        }

        // Fronds
        let frondColors = [
            Color(red: 0.2, green: 0.55, blue: 0.25),
            Color(red: 0.25, green: 0.6, blue: 0.3),
            Color(red: 0.15, green: 0.5, blue: 0.2),
        ]
        let frondAngles: [(dx: CGFloat, dy: CGFloat, len: CGFloat)] = [
            (-8, -4, 9), (-5, -6, 8), (0, -7, 7), (5, -5, 8), (7, -3, 7), (-3, -2, 6),
        ]
        for (i, frond) in frondAngles.enumerated() {
            let color = frondColors[i % frondColors.count]
            for step in stride(from: CGFloat(0), through: frond.len, by: 1.5) {
                let frac = step / frond.len
                let fx = palmX + sin(curve) * 2 + frond.dx * frac
                let fy = trunkTop + frond.dy * frac
                let w: CGFloat = 2.5 - frac * 1.5
                ctx.fill(
                    Path(CGRect(x: fx - w / 2, y: fy, width: max(w, 0.5), height: 1.5)),
                    with: .color(color.opacity(alpha - Double(frac) * 0.2))
                )
            }
        }

        // Coconuts
        ctx.fill(
            Path(CGRect(x: palmX - 1, y: trunkTop + 1, width: 2, height: 2)),
            with: .color(Color(red: 0.45, green: 0.3, blue: 0.15).opacity(alpha + 0.1))
        )
        ctx.fill(
            Path(CGRect(x: palmX + 1.5, y: trunkTop + 2, width: 2, height: 2)),
            with: .color(Color(red: 0.5, green: 0.33, blue: 0.18).opacity(alpha))
        )
    }

    /// Draw background scenery elements (trees, boulders, branches) behind creatures.
    /// Rendered between sky and ground, before creature sprites.
    func drawBackgroundScenery(
        ctx: inout GraphicsContext,
        left: CGFloat, width: CGFloat, grassY: CGFloat
    ) {
        let midX = left + width / 2

        switch self {
        case .meadow:
            break  // meadow keeps it clean

        case .moon:
            break  // clean lunar surface, no background clutter

        case .island:
            // Palm trees at varying positions and sizes
            let palmPositions: [(x: CGFloat, height: CGFloat, curve: CGFloat, alpha: Double)] = [
                (0.08, 12, -0.5, 0.35),  // small far left
                (0.25, 18, 0.7,  0.55),  // medium left
                (0.55, 14, -0.4, 0.4),   // small center-right
                (0.78, 22, 0.9,  0.7),   // tall right
                (0.92, 15, -0.6, 0.45),  // medium far right
            ]
            for palm in palmPositions {
                Self.drawPalmTree(
                    ctx: &ctx, left: left, width: width, grassY: grassY,
                    xFrac: palm.x, height: palm.height, curve: palm.curve, alpha: palm.alpha
                )
            }

        case .alien:
            // Alien: sparse strange trees
            let alienTrees: [(x: CGFloat, h: CGFloat, w: CGFloat, alpha: Double)] = [
                (0.12, 22, 10, 0.3), (0.3, 18, 8, 0.25),
                (0.75, 25, 12, 0.35), (0.9, 16, 7, 0.2),
            ]
            let alienTreeColor = Color(red: 0.08, green: 0.25, blue: 0.08)
            for tree in alienTrees {
                let tx = left + width * tree.x
                let base = grassY
                ctx.fill(
                    Path(CGRect(x: tx - 1, y: base - 5, width: 2, height: 5)),
                    with: .color(Color(red: 0.2, green: 0.3, blue: 0.12).opacity(tree.alpha))
                )
                let layers = Int(tree.h / 3)
                let halfW = tree.w / 2
                for layer in 0..<layers {
                    let frac = CGFloat(layer) / CGFloat(layers)
                    let layerW = halfW * (1.0 - frac * 0.7)
                    let ly = base - 5 - CGFloat(layer) * 3
                    ctx.fill(
                        Path(CGRect(x: tx - layerW, y: ly - 3, width: layerW * 2, height: 3.5)),
                        with: .color(alienTreeColor.opacity(tree.alpha - Double(frac) * 0.05))
                    )
                }
            }

        case .forest:
            // Dense forest — many trees at varying depths
            let farTrees: [(x: CGFloat, h: CGFloat, w: CGFloat, alpha: Double)] = [
                // Far layer (faint, small)
                (0.05, 14, 6,  0.15), (0.18, 16, 7,  0.18), (0.35, 13, 5,  0.14),
                (0.5,  15, 6,  0.16), (0.65, 14, 5,  0.15), (0.82, 16, 7,  0.17),
                (0.95, 13, 5,  0.14),
            ]
            let midTrees: [(x: CGFloat, h: CGFloat, w: CGFloat, alpha: Double)] = [
                // Mid layer
                (0.08, 20, 9,  0.28), (0.25, 22, 10, 0.3),
                (0.55, 18, 8,  0.25), (0.72, 24, 11, 0.32), (0.92, 19, 9,  0.27),
            ]
            let nearTrees: [(x: CGFloat, h: CGFloat, w: CGFloat, alpha: Double)] = [
                // Near layer (darker, larger)
                (0.15, 28, 13, 0.45), (0.42, 25, 11, 0.4),
                (0.7,  30, 14, 0.5),  (0.88, 22, 10, 0.38),
            ]

            let darkGreen = Color(red: 0.06, green: 0.15, blue: 0.06)
            let midGreen = Color(red: 0.08, green: 0.2, blue: 0.08)
            let trunkColor = Color(red: 0.25, green: 0.18, blue: 0.1)

            // Draw far to near for depth
            for (trees, color) in [(farTrees, darkGreen), (midTrees, midGreen), (nearTrees, darkGreen)] {
                for tree in trees {
                    let tx = left + width * tree.x
                    let base = grassY

                    // Trunk
                    ctx.fill(
                        Path(CGRect(x: tx - 1, y: base - 4, width: 2, height: 4)),
                        with: .color(trunkColor.opacity(tree.alpha * 0.8))
                    )

                    // Layered canopy
                    let layers = Int(tree.h / 2.5)
                    let halfW = tree.w / 2
                    for layer in 0..<layers {
                        let frac = CGFloat(layer) / CGFloat(layers)
                        let layerW = halfW * (1.0 - frac * 0.65)
                        let ly = base - 4 - CGFloat(layer) * 2.5
                        ctx.fill(
                            Path(CGRect(x: tx - layerW, y: ly - 2.5, width: layerW * 2, height: 3)),
                            with: .color(color.opacity(tree.alpha - Double(frac) * 0.08))
                        )
                    }
                }
            }

        case .alien:
            // Alien: sparse strange trees (reuses old forest style)
            let trees: [(x: CGFloat, h: CGFloat, w: CGFloat, alpha: Double)] = [
                (0.12, 22, 10, 0.3), (0.3, 18, 8, 0.25),
                (0.75, 25, 12, 0.35), (0.9, 16, 7, 0.2),
            ]
            let treeColor = Color(red: 0.08, green: 0.25, blue: 0.08)
            for tree in trees {
                let tx = left + width * tree.x
                let base = grassY
                ctx.fill(
                    Path(CGRect(x: tx - 1, y: base - 5, width: 2, height: 5)),
                    with: .color(Color(red: 0.2, green: 0.3, blue: 0.12).opacity(tree.alpha))
                )
                let layers = Int(tree.h / 3)
                let halfW = tree.w / 2
                for layer in 0..<layers {
                    let frac = CGFloat(layer) / CGFloat(layers)
                    let layerW = halfW * (1.0 - frac * 0.7)
                    let ly = base - 5 - CGFloat(layer) * 3
                    ctx.fill(
                        Path(CGRect(x: tx - layerW, y: ly - 3, width: layerW * 2, height: 3.5)),
                        with: .color(treeColor.opacity(tree.alpha - Double(frac) * 0.05))
                    )
                }
            }

        case .sakura:
            // Cherry blossom tree branch arching from the side
            let branchStartX = left + width * 0.1
            let branchStartY = grassY - 5

            // Main branch curving upward and across
            for i in 0..<12 {
                let t = CGFloat(i) / 12.0
                let bx = branchStartX + t * width * 0.6
                let by = branchStartY - sin(t * .pi * 0.7) * 18
                let w: CGFloat = 2.0 - t * 1.2
                ctx.fill(
                    Path(CGRect(x: bx, y: by, width: max(w, 0.5), height: 2)),
                    with: .color(Color(red: 0.4, green: 0.28, blue: 0.22).opacity(0.5))
                )
            }

            // Blossom clusters along the branch
            var rng = StableRNG(seed: 88)
            let blossomColors = [
                Color(red: 1.0, green: 0.75, blue: 0.82),
                Color(red: 1.0, green: 0.65, blue: 0.78),
                Color(red: 1.0, green: 0.85, blue: 0.88),
                Color(red: 0.95, green: 0.7, blue: 0.8),
            ]
            for i in 0..<16 {
                let t = CGFloat(i) / 16.0
                let cx = branchStartX + t * width * 0.6 + CGFloat.random(in: -3...3, using: &rng)
                let cy = branchStartY - sin(t * .pi * 0.7) * 18 + CGFloat.random(in: -4...2, using: &rng)
                let sz = CGFloat.random(in: 1.5...3, using: &rng)
                let color = blossomColors[i % blossomColors.count]
                ctx.fill(
                    Path(CGRect(x: cx, y: cy, width: sz, height: sz)),
                    with: .color(color.opacity(Double.random(in: 0.4...0.7, using: &rng)))
                )
            }

        case .custom:
            break  // no scenery — user image is the background
        }
    }

    /// Draw ground-level accents for this theme.
    func drawGroundAccents(
        ctx: inout GraphicsContext,
        grassX: CGFloat, grassY: CGFloat, grassWidth: CGFloat
    ) {
        var rng = StableRNG(seed: 99)

        switch self {
        case .meadow:
            GrassIslandView.drawSeasonalAccents(
                ctx: &ctx, season: Season.current,
                grassX: grassX, grassY: grassY, grassWidth: grassWidth
            )

        case .moon:
            // Small craters
            for _ in 0..<4 {
                let cx = grassX + CGFloat.random(in: 4...(grassWidth - 4), using: &rng)
                let cy = grassY - CGFloat.random(in: 0...2, using: &rng)
                let w = CGFloat.random(in: 3...5, using: &rng)
                // Crater rim (lighter)
                ctx.fill(
                    Path(CGRect(x: cx, y: cy - 0.5, width: w, height: 1.5)),
                    with: .color(Color(red: 0.55, green: 0.52, blue: 0.48).opacity(0.6))
                )
                // Crater interior (darker)
                ctx.fill(
                    Path(CGRect(x: cx + 0.5, y: cy, width: w - 1, height: 1)),
                    with: .color(Color(red: 0.2, green: 0.19, blue: 0.18).opacity(0.5))
                )
            }

        case .island:
            // Ocean water at the bottom of the ground area
            ctx.fill(
                Path(CGRect(x: grassX - 4, y: grassY + 3, width: grassWidth + 8, height: 6)),
                with: .color(Color(red: 0.2, green: 0.6, blue: 0.85).opacity(0.5))
            )
            ctx.fill(
                Path(CGRect(x: grassX - 4, y: grassY + 5, width: grassWidth + 8, height: 4)),
                with: .color(Color(red: 0.15, green: 0.5, blue: 0.8).opacity(0.4))
            )
            // Foam/wave line where sand meets water
            ctx.fill(
                Path(CGRect(x: grassX, y: grassY + 2, width: grassWidth, height: 1.5)),
                with: .color(Color.white.opacity(0.35))
            )
            ctx.fill(
                Path(CGRect(x: grassX + 3, y: grassY + 1.5, width: grassWidth - 6, height: 1)),
                with: .color(Color.white.opacity(0.2))
            )
            // Shells on sand
            for _ in 0..<2 {
                let sx = grassX + CGFloat.random(in: 4...(grassWidth - 4), using: &rng)
                let sy = grassY - CGFloat.random(in: 0...1, using: &rng)
                ctx.fill(
                    Path(CGRect(x: sx, y: sy - 1, width: 2.5, height: 1.5)),
                    with: .color(Color(red: 0.95, green: 0.9, blue: 0.8).opacity(0.7))
                )
            }

        case .alien:
            // Alien reuses forest mushrooms/ferns
            for _ in 0..<3 {
                let mx = grassX + CGFloat.random(in: 6...(grassWidth - 6), using: &rng)
                let my = grassY - 1
                // Glowing mushroom
                ctx.fill(
                    Path(CGRect(x: mx + 0.5, y: my - 2, width: 1, height: 2)),
                    with: .color(Color(red: 0.5, green: 0.7, blue: 0.4).opacity(0.6))
                )
                ctx.fill(
                    Path(CGRect(x: mx - 0.5, y: my - 3, width: 3, height: 1.5)),
                    with: .color(Color(red: 0.3, green: 0.8, blue: 0.3).opacity(0.6))
                )
            }

        case .forest:
            // Mushrooms and ferns
            for _ in 0..<3 {
                let mx = grassX + CGFloat.random(in: 6...(grassWidth - 6), using: &rng)
                let my = grassY - 1
                if Bool.random(using: &rng) {
                    // Mushroom
                    ctx.fill(
                        Path(CGRect(x: mx + 0.5, y: my - 2, width: 1, height: 2)),
                        with: .color(Color(red: 0.7, green: 0.6, blue: 0.45).opacity(0.7))
                    )
                    ctx.fill(
                        Path(CGRect(x: mx - 0.5, y: my - 3, width: 3, height: 1.5)),
                        with: .color(Color(red: 0.7, green: 0.2, blue: 0.15).opacity(0.7))
                    )
                } else {
                    // Fern frond
                    ctx.fill(
                        Path(CGRect(x: mx, y: my - 4, width: 1, height: 4)),
                        with: .color(Color(red: 0.15, green: 0.45, blue: 0.2).opacity(0.6))
                    )
                    ctx.fill(
                        Path(CGRect(x: mx - 1, y: my - 3, width: 1, height: 1)),
                        with: .color(Color(red: 0.2, green: 0.5, blue: 0.25).opacity(0.5))
                    )
                    ctx.fill(
                        Path(CGRect(x: mx + 1, y: my - 2, width: 1, height: 1)),
                        with: .color(Color(red: 0.2, green: 0.5, blue: 0.25).opacity(0.5))
                    )
                }
            }

        case .sakura:
            // Small lanterns
            for _ in 0..<2 {
                let lx = grassX + CGFloat.random(in: 8...(grassWidth - 8), using: &rng)
                let ly = grassY - 1
                // Pole
                ctx.fill(
                    Path(CGRect(x: lx + 0.5, y: ly - 5, width: 1, height: 5)),
                    with: .color(Color(red: 0.4, green: 0.35, blue: 0.3).opacity(0.6))
                )
                // Lantern body
                ctx.fill(
                    Path(CGRect(x: lx - 0.5, y: ly - 7, width: 3, height: 2.5)),
                    with: .color(Color(red: 1.0, green: 0.85, blue: 0.7).opacity(0.7))
                )
                // Glow
                ctx.fill(
                    Path(CGRect(x: lx, y: ly - 6.5, width: 2, height: 1.5)),
                    with: .color(Color(red: 1.0, green: 0.9, blue: 0.6).opacity(0.4))
                )
            }

        case .custom:
            break  // no accents — user image is the background
        }
    }

}

// MARK: - Ground Texture Drawing

extension SceneTheme {
    /// Draw ground-level texture (grass blades for meadow, themed texture for others).
    func drawGroundTexture(
        ctx: inout GraphicsContext,
        grassX: CGFloat, grassY: CGFloat, grassWidth: CGFloat
    ) {
        var rng = StableRNG(seed: 42)
        let ground = groundColors

        switch self {
        case .meadow:
            // Grass blades (existing behaviour)
            let season = Season.current
            let grass = season.grassColor
            let bladeCount = Int(grassWidth / 2.5)
            for i in 0..<bladeCount {
                let bx = grassX + CGFloat(i) * 2.5 + CGFloat.random(in: -1...1, using: &rng)
                let h = CGFloat.random(in: 4...10, using: &rng)
                let rect = CGRect(x: bx, y: grassY - h + 2, width: 1.5, height: h)
                let opacity = Double.random(in: 0.4...0.9, using: &rng)
                ctx.fill(Path(rect), with: .color(grass.blade.opacity(opacity)))

                if season == .winter && i % 3 == 0 {
                    let frostRect = CGRect(x: bx, y: grassY - h + 2, width: 1.5, height: 2)
                    ctx.fill(Path(frostRect), with: .color(Color.white.opacity(0.5 * opacity)))
                }
            }

        case .moon:
            // Rough lunar surface — scattered small rocks
            let rockCount = Int(grassWidth / 4)
            for i in 0..<rockCount {
                let rx = grassX + CGFloat(i) * 4 + CGFloat.random(in: -1...1, using: &rng)
                let h = CGFloat.random(in: 1...3, using: &rng)
                let w = CGFloat.random(in: 1...2.5, using: &rng)
                let opacity = Double.random(in: 0.2...0.5, using: &rng)
                ctx.fill(
                    Path(CGRect(x: rx, y: grassY - h + 1, width: w, height: h)),
                    with: .color(ground.surface.opacity(opacity))
                )
            }

        case .island:
            // Sandy ripples
            let rippleCount = Int(grassWidth / 5)
            for i in 0..<rippleCount {
                let rx = grassX + CGFloat(i) * 5 + CGFloat.random(in: -1...2, using: &rng)
                let w = CGFloat.random(in: 3...6, using: &rng)
                let opacity = Double.random(in: 0.15...0.35, using: &rng)
                ctx.fill(
                    Path(CGRect(x: rx, y: grassY - 1, width: w, height: 0.8)),
                    with: .color(Color(red: 0.85, green: 0.8, blue: 0.65).opacity(opacity))
                )
            }

        case .alien:
            // Alien moss (same as forest but greener)
            let alienMossCount = Int(grassWidth / 2.5)
            for i in 0..<alienMossCount {
                let mx = grassX + CGFloat(i) * 2.5 + CGFloat.random(in: -1...1, using: &rng)
                let h = CGFloat.random(in: 2...5, using: &rng)
                let opacity = Double.random(in: 0.3...0.7, using: &rng)
                let color = Color(red: 0.15, green: 0.4, blue: 0.12)
                ctx.fill(
                    Path(CGRect(x: mx, y: grassY - h + 1, width: 1.5, height: h)),
                    with: .color(color.opacity(opacity))
                )
            }

        case .forest:
            // Leaf litter and fallen twigs
            let mossCount = Int(grassWidth / 2.5)
            for i in 0..<mossCount {
                let mx = grassX + CGFloat(i) * 2.5 + CGFloat.random(in: -1...1, using: &rng)
                let h = CGFloat.random(in: 2...5, using: &rng)
                let opacity = Double.random(in: 0.3...0.7, using: &rng)
                let colors: [Color] = [
                    Color(red: 0.15, green: 0.4, blue: 0.12),
                    Color(red: 0.2, green: 0.35, blue: 0.15),
                    Color(red: 0.25, green: 0.3, blue: 0.1),
                ]
                let color = colors[i % colors.count]
                ctx.fill(
                    Path(CGRect(x: mx, y: grassY - h + 1, width: 1.5, height: h)),
                    with: .color(color.opacity(opacity))
                )
            }

        case .sakura:
            // Stone path texture — subtle lighter patches
            let stoneCount = Int(grassWidth / 6)
            for i in 0..<stoneCount {
                let sx = grassX + CGFloat(i) * 6 + CGFloat.random(in: 0...3, using: &rng)
                let w = CGFloat.random(in: 3...5, using: &rng)
                let h = CGFloat.random(in: 1.5...3, using: &rng)
                let opacity = Double.random(in: 0.15...0.3, using: &rng)
                ctx.fill(
                    Path(CGRect(x: sx, y: grassY - h + 1, width: w, height: h)),
                    with: .color(Color(red: 0.8, green: 0.75, blue: 0.7).opacity(opacity))
                )
            }

        case .custom:
            break  // no ground texture — user image is the background
        }
    }
}

// Stable RNG — same as in GrassIslandView but accessible to SceneTheme
private struct StableRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
