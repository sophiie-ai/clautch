import SwiftUI

/// Shared layout constants for the notch panel, computed once per frame.
struct PanelLayout {
    let notchHeight: CGFloat
    let groundH: CGFloat = 7
    let logH: CGFloat = 56
    let scenePad: CGFloat = 2
    let minSky: CGFloat = 38

    let showLog: Bool
    let showStatus: Bool
    let logSpace: CGFloat
    let statusSpace: CGFloat
    let maxDrop: CGFloat
    let grassLineY: CGFloat
    let bottom: CGFloat

    init(viewHeight: CGFloat, isExpanded: Bool) {
        let screen = NSScreen.screens.first(where: { $0.hasNotch }) ?? NSScreen.main
        notchHeight = screen?.effectiveNotchHeight ?? 24
        showLog = AnimationSettings.shared.showEventLog
        showStatus = AnimationSettings.shared.showStatusBar
        logSpace = showLog ? logH : 0
        statusSpace = showStatus ? 8 : 0

        let fullDrop = viewHeight - notchHeight
        let neededDrop = minSky + groundH + logSpace + statusSpace + scenePad
        maxDrop = min(fullDrop, neededDrop)

        let dropHeight = isExpanded ? maxDrop : 0
        bottom = notchHeight + dropHeight
        grassLineY = isExpanded
            ? bottom - groundH - logSpace - statusSpace - scenePad
            : notchHeight
    }
}

// MARK: - Season

enum Season: String, CaseIterable {
    case spring, summer, autumn, winter

    static var current: Season {
        let month = Calendar.current.component(.month, from: Date())
        let southern = UserDefaults.standard.bool(forKey: "com.clautch.southernHemisphere")
        let base: Season = switch month {
        case 3...5:  .spring
        case 6...8:  .summer
        case 9...11: .autumn
        default:     .winter
        }
        // Flip for southern hemisphere
        if southern {
            return switch base {
            case .spring: .autumn
            case .summer: .winter
            case .autumn: .spring
            case .winter: .summer
            }
        }
        return base
    }

    var grassColor: (blade: Color, ground: Color) {
        switch self {
        case .spring: return (Color(red: 0.25, green: 0.6, blue: 0.3), Color(red: 0.14, green: 0.4, blue: 0.18))
        case .summer: return (Color(red: 0.2, green: 0.5, blue: 0.25), Color(red: 0.12, green: 0.35, blue: 0.15))
        case .autumn: return (Color(red: 0.6, green: 0.4, blue: 0.15), Color(red: 0.35, green: 0.22, blue: 0.1))
        case .winter: return (Color(red: 0.35, green: 0.5, blue: 0.4), Color(red: 0.18, green: 0.28, blue: 0.25))
        }
    }

    /// Sky tint shift applied on top of time-of-day interpolation.
    var skyTint: (r: Double, g: Double, b: Double) {
        switch self {
        case .spring: return (0.03, 0.0, 0.02)    // slightly pink
        case .summer: return (0.0, 0.0, 0.0)      // no shift (baseline)
        case .autumn: return (0.04, 0.01, -0.03)   // warmer
        case .winter: return (-0.02, 0.0, 0.04)    // cooler/bluer
        }
    }

    var particleCount: Int {
        switch self {
        case .spring: return 10
        case .summer: return 8
        case .autumn: return 12
        case .winter: return 14
        }
    }
}

/// Renders a Dynamic-Island-style panel extending from the notch.
/// Collapsed: small bump with creature head peeking out.
/// Expanded: scenic panel with sky, grass, creatures, event log, status bar.
struct GrassIslandView: View {
    let creatures: [CreatureDisplay]
    var isExpanded: Bool = false
    var isWalking: Bool = false

    @State private var bounceScale: CGFloat = 1.0
    @State private var bounceOffset: CGFloat = 0

    private var creatureSize: CGFloat {
        if !isExpanded { return 9 } // smaller when collapsed
        switch creatures.count {
        case 0...3: return 15
        case 4:     return 13
        case 5:     return 11
        default:    return 9
        }
    }

    /// Sky colors and star count, smoothly interpolated by time of day with seasonal tint.
    private var skyTheme: (top: Color, bottom: Color, stars: Int) {
        let cal = Calendar.current
        let now = Date()
        let h = cal.component(.hour, from: now)
        let m = cal.component(.minute, from: now)
        let t = Double(h) + Double(m) / 60.0  // fractional hour (e.g. 7.5 = 7:30)

        // Keyframes: (hour, topR, topG, topB, botR, botG, botB, stars)
        let keys: [(h: Double, tr: Double, tg: Double, tb: Double, br: Double, bg: Double, bb: Double, s: Double)] = [
            (0,  0.08, 0.10, 0.25, 0.12, 0.18, 0.35, 14),  // Midnight
            (6,  0.08, 0.10, 0.25, 0.12, 0.18, 0.35, 14),  // Pre-dawn
            (7,  0.45, 0.30, 0.40, 0.75, 0.45, 0.30,  3),  // Dawn
            (8,  0.20, 0.45, 0.75, 0.40, 0.65, 0.85,  0),  // Morning
            (17, 0.20, 0.45, 0.75, 0.40, 0.65, 0.85,  0),  // Late afternoon
            (18, 0.35, 0.20, 0.45, 0.70, 0.35, 0.30,  4),  // Dusk
            (19, 0.12, 0.12, 0.30, 0.15, 0.20, 0.35, 10),  // Early night
            (24, 0.08, 0.10, 0.25, 0.12, 0.18, 0.35, 14),  // Midnight wrap
        ]

        // Find surrounding keyframes and interpolate
        var lo = keys[0], hi = keys[1]
        for i in 0..<(keys.count - 1) {
            if t >= keys[i].h && t < keys[i + 1].h {
                lo = keys[i]; hi = keys[i + 1]; break
            }
        }
        let span = hi.h - lo.h
        let f = span > 0 ? (t - lo.h) / span : 0  // blend factor 0..1

        // Apply seasonal tint
        let tint = Season.current.skyTint
        func clamp(_ v: Double) -> Double { min(1, max(0, v)) }

        let top = Color(red: clamp(lo.tr + (hi.tr - lo.tr) * f + tint.r),
                        green: clamp(lo.tg + (hi.tg - lo.tg) * f + tint.g),
                        blue: clamp(lo.tb + (hi.tb - lo.tb) * f + tint.b))
        let bot = Color(red: clamp(lo.br + (hi.br - lo.br) * f + tint.r),
                        green: clamp(lo.bg + (hi.bg - lo.bg) * f + tint.g),
                        blue: clamp(lo.bb + (hi.bb - lo.bb) * f + tint.b))
        let starBase = Int((lo.s + (hi.s - lo.s) * f).rounded())
        // Winter gets more stars, summer fewer
        let starAdjust = Season.current == .winter ? 3 : (Season.current == .summer ? -2 : 0)
        let stars = max(0, starBase + starAdjust)
        return (top, bot, stars)
    }

    var body: some View {
        let sky = skyTheme
        let season = Season.current
        let grass = season.grassColor
        Canvas { ctx, size in
            let layout = PanelLayout(viewHeight: size.height, isExpanded: isExpanded)
            let notchWidth = notchWidthInWindow(totalWidth: size.width)
            let midX = size.width / 2
            let notchHalf = notchWidth / 2
            let expandedPanelHalf = min(size.width / 2 - 2, notchHalf + 50)
            let panelHalf = isExpanded ? expandedPanelHalf : notchHalf + 20
            let bottom = layout.bottom
            let r: CGFloat = isExpanded ? 8 : 6
            let dropHeight = isExpanded ? layout.maxDrop : CGFloat(0)
            let cr = min(r, dropHeight / 2)

            // 1. Clip path for the island shape
            var path = Path()

            if isExpanded {
                // Expanded: full rectangle from top edge, no top rounded corners
                // Straight across the top, including behind the notch
                path.move(to: CGPoint(x: midX - panelHalf, y: 0))
                path.addLine(to: CGPoint(x: midX + panelHalf, y: 0))
                path.addLine(to: CGPoint(x: midX + panelHalf, y: bottom - cr))
                path.addQuadCurve(
                    to: CGPoint(x: midX + panelHalf - cr, y: bottom),
                    control: CGPoint(x: midX + panelHalf, y: bottom)
                )
                path.addLine(to: CGPoint(x: midX - panelHalf + cr, y: bottom))
                path.addQuadCurve(
                    to: CGPoint(x: midX - panelHalf, y: bottom - cr),
                    control: CGPoint(x: midX - panelHalf, y: bottom)
                )
                path.addLine(to: CGPoint(x: midX - panelHalf, y: 0))
            } else {
                // Collapsed: transparent — no background at all, just creature overlay
                // Use a zero-area path so nothing draws
                path.move(to: CGPoint(x: midX, y: 0))
                path.addLine(to: CGPoint(x: midX, y: 0))
            }
            path.closeSubpath()

            if isExpanded {
                // 2. Draw scenic background
                let grassY = layout.grassLineY

                // Sky gradient (fills from top of screen)
                ctx.clip(to: path)
                let skyGradient = Gradient(colors: [sky.top, sky.bottom])
                ctx.fill(
                    Path(CGRect(x: midX - panelHalf, y: 0, width: panelHalf * 2, height: grassY)),
                    with: .linearGradient(skyGradient, startPoint: CGPoint(x: midX, y: 0), endPoint: CGPoint(x: midX, y: grassY))
                )

                // Stars (tiny dots in sky) — count varies by time of day
                let skyTop_y = layout.notchHeight + 5
                let skyBottom_y = grassY - 5
                let starCount = layout.showLog ? sky.stars + 6 : sky.stars
                if skyBottom_y > skyTop_y + 2 && starCount > 0 {
                    var starRng = StableRNG(seed: 77)
                    for _ in 0..<starCount {
                        let sx = midX - panelHalf + CGFloat.random(in: 0...(panelHalf * 2), using: &starRng)
                        let sy = CGFloat.random(in: skyTop_y...skyBottom_y, using: &starRng)
                        let alpha = Double.random(in: 0.3...0.7, using: &starRng)
                        ctx.fill(Path(CGRect(x: sx, y: sy, width: 1, height: 1)), with: .color(.white.opacity(alpha)))
                    }
                }

                // Weather particles — seasonal effects in the sky
                let t = Date.timeIntervalSinceReferenceDate
                let pCount = season.particleCount
                let leftEdge = midX - panelHalf
                let width = panelHalf * 2
                for i in 0..<pCount {
                    let seed = Double(i) * 137.5  // golden angle offset per particle
                    Self.drawWeatherParticle(
                        ctx: &ctx, season: season, index: i, seed: seed, time: t,
                        left: leftEdge, width: width,
                        skyTop: skyTop_y, skyBottom: grassY, starCount: starCount
                    )
                }

                // Ground — fixed height
                ctx.fill(
                    Path(CGRect(x: midX - panelHalf, y: grassY, width: panelHalf * 2, height: bottom - grassY)),
                    with: .color(grass.ground)
                )

                // Grass blades
                var rng = StableRNG(seed: 42)
                let grassWidth = panelHalf * 2 - 8
                let grassX = midX - grassWidth / 2
                let bladeCount = Int(grassWidth / 2.5)
                for i in 0..<bladeCount {
                    let bx = grassX + CGFloat(i) * 2.5 + CGFloat.random(in: -1...1, using: &rng)
                    let h = CGFloat.random(in: 4...10, using: &rng)
                    let rect = CGRect(x: bx, y: grassY - h + 2, width: 1.5, height: h)
                    let opacity = Double.random(in: 0.4...0.9, using: &rng)
                    ctx.fill(Path(rect), with: .color(grass.blade.opacity(opacity)))

                    // Winter: frost-white tips on some blades
                    if season == .winter && i % 3 == 0 {
                        let frostRect = CGRect(x: bx, y: grassY - h + 2, width: 1.5, height: 2)
                        ctx.fill(Path(frostRect), with: .color(Color.white.opacity(0.5 * opacity)))
                    }
                }

                // Seasonal ground accents
                Self.drawSeasonalAccents(
                    ctx: &ctx, season: season,
                    grassX: grassX, grassY: grassY, grassWidth: grassWidth
                )

                // Dark section below ground for event log + status bar
                if layout.showLog || layout.showStatus {
                    let darkY = grassY + layout.groundH
                    ctx.fill(
                        Path(CGRect(x: midX - panelHalf, y: darkY, width: panelHalf * 2, height: bottom - darkY)),
                        with: .color(Color.black.opacity(0.85))
                    )
                    if layout.showLog {
                        ctx.fill(
                            Path(CGRect(x: midX - panelHalf + 8, y: darkY, width: panelHalf * 2 - 16, height: 1)),
                            with: .color(.white.opacity(0.1))
                        )
                    }
                }
            } else {
                // Collapsed: nothing drawn — transparent background, creature only
            }
        }
        .drawingGroup()  // GPU-rasterize static scenic content
        .overlay {
            // SwiftUI creature sprites
            GeometryReader { geo in
                let layout = PanelLayout(viewHeight: geo.size.height, isExpanded: isExpanded)
                let grassLineY = layout.grassLineY

                CreatureIslandOverlay(
                    creatures: creatures,
                    isExpanded: isExpanded,
                    isWalking: isWalking,
                    creatureSize: creatureSize,
                    bounceScale: bounceScale,
                    bounceOffset: bounceOffset,
                    grassLineY: grassLineY,
                    viewWidth: geo.size.width,
                    notchWidthFn: notchWidthInWindow
                )

                ProximityEffectsView(
                    creatures: creatures,
                    isExpanded: isExpanded,
                    creatureSize: creatureSize,
                    grassLineY: grassLineY,
                    viewWidth: geo.size.width
                )
            }
        }
        // Event log + status bar overlays (positioned within visible panel)
        .overlay {
            if (AnimationSettings.shared.showEventLog || AnimationSettings.shared.showStatusBar) && isExpanded {
                GeometryReader { geo in
                    let layout = PanelLayout(viewHeight: geo.size.height, isExpanded: true)
                    let logTop = layout.grassLineY + layout.groundH
                    let contentWidth = geo.size.width - 72

                    if layout.showLog {
                        EventLogOverlay()
                            .frame(width: contentWidth, height: layout.logH, alignment: .top)
                            .padding(.top, 2)
                            .position(x: geo.size.width / 2, y: logTop + layout.logH / 2)
                            .transition(.opacity.combined(with: .offset(y: 10)))
                    }

                    if layout.showStatus {
                        StatusBarOverlay()
                            .frame(width: contentWidth)
                            .position(x: geo.size.width / 2, y: layout.bottom - layout.scenePad - layout.statusSpace / 2)
                            .transition(.opacity)
                    }
                }
            }
        }
        // Clip everything to the panel shape
        .clipShape(PanelClipShape(isExpanded: isExpanded, notchHalf: notchHalfForClip, panelHalf: panelHalfForClip, notchHeight: notchHeightForClip, cr: isExpanded ? 8 : 6))
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
        .onChange(of: isExpanded) { _, expanded in
            if expanded {
                triggerLandingBounce()
            } else {
                bounceScale = 1.0
                bounceOffset = 0
            }
        }
    }

    private func triggerLandingBounce() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeIn(duration: 0.08)) {
                bounceScale = 0.7
                bounceOffset = 4
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.35)) {
                    bounceScale = 1.0
                    bounceOffset = 0
                }
            }
        }
    }

    // Pre-computed values for the clip shape (works on both notch and non-notch screens)
    private var activeScreen: NSScreen? {
        NSScreen.screens.first(where: { $0.hasNotch }) ?? NSScreen.main
    }
    private var notchHeightForClip: CGFloat {
        activeScreen?.effectiveNotchHeight ?? 24
    }
    private var notchHalfForClip: CGFloat {
        guard let screen = activeScreen,
              let win = screen.notchWindowFrame else { return 0 }
        let notch = screen.effectiveNotchSize
        return (notch.width * win.width / win.width) / 2
    }
    private var panelHalfForClip: CGFloat {
        guard let screen = activeScreen,
              let win = screen.notchWindowFrame else { return 100 }
        let notch = screen.effectiveNotchSize
        let notchHalf = (notch.width * win.width / win.width) / 2
        return min(win.width / 2 - 2, notchHalf + 50)
    }

    private func notchWidthInWindow(totalWidth: CGFloat) -> CGFloat {
        guard let screen = activeScreen,
              let win = screen.notchWindowFrame else { return totalWidth * 0.7 }
        let notch = screen.effectiveNotchSize
        return notch.width * totalWidth / win.width
    }
}

// MARK: - Panel Clip Shape

struct PanelClipShape: Shape {
    let isExpanded: Bool
    let notchHalf: CGFloat
    let panelHalf: CGFloat
    let notchHeight: CGFloat
    let cr: CGFloat

    func path(in rect: CGRect) -> Path {
        let midX = rect.midX
        let bottom = rect.maxY

        var path = Path()
        if isExpanded {
            path.move(to: CGPoint(x: midX - panelHalf, y: 0))
            path.addLine(to: CGPoint(x: midX + panelHalf, y: 0))
            path.addLine(to: CGPoint(x: midX + panelHalf, y: bottom - cr))
            path.addQuadCurve(
                to: CGPoint(x: midX + panelHalf - cr, y: bottom),
                control: CGPoint(x: midX + panelHalf, y: bottom))
            path.addLine(to: CGPoint(x: midX - panelHalf + cr, y: bottom))
            path.addQuadCurve(
                to: CGPoint(x: midX - panelHalf, y: bottom - cr),
                control: CGPoint(x: midX - panelHalf, y: bottom))
            path.addLine(to: CGPoint(x: midX - panelHalf, y: 0))
        } else {
            // Collapsed: clip to just the notch/menu bar height (top of view)
            let clipHeight = min(notchHeight, rect.height)
            path.addRect(CGRect(x: rect.minX, y: 0, width: rect.width, height: clipHeight))
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Weather Particles

extension GrassIslandView {
    /// Draw a single weather particle. Uses time + seed for deterministic, smooth animation.
    static func drawWeatherParticle(
        ctx: inout GraphicsContext, season: Season, index: Int, seed: Double, time: Double,
        left: CGFloat, width: CGFloat, skyTop: CGFloat, skyBottom: CGFloat, starCount: Int
    ) {
        let skyH = skyBottom - skyTop
        guard skyH > 4 else { return }

        switch season {
        case .spring:
            // Cherry blossom petals — gentle sway + slow fall
            let cycle = 8.0  // seconds per full descent
            let phase = (time + seed).truncatingRemainder(dividingBy: cycle) / cycle  // 0..1
            let x = left + CGFloat((seed * 0.618).truncatingRemainder(dividingBy: 1.0)) * width
                + CGFloat(sin((time + seed) * 1.2)) * 6  // horizontal sway
            let y = skyTop + CGFloat(phase) * skyH
            let alpha = 1.0 - abs(phase - 0.5) * 0.6  // fade at edges
            let petalColor = index % 2 == 0
                ? Color(red: 1.0, green: 0.7, blue: 0.8)
                : Color(red: 1.0, green: 0.8, blue: 0.85)
            ctx.fill(Path(CGRect(x: x, y: y, width: 2, height: 1.5)),
                     with: .color(petalColor.opacity(alpha * 0.7)))

        case .summer:
            // Fireflies — random float with glow, only at night (when stars are visible)
            guard starCount > 2 else { return }
            let cx = left + CGFloat((seed * 0.618).truncatingRemainder(dividingBy: 1.0)) * width
            let baseY = skyTop + CGFloat((seed * 0.382).truncatingRemainder(dividingBy: 1.0)) * skyH
            let x = cx + CGFloat(sin(time * 0.8 + seed)) * 8
            let y = baseY + CGFloat(cos(time * 0.6 + seed * 1.3)) * 5
            let pulse = 0.3 + 0.7 * abs(sin(time * 2.0 + seed))
            // Glow
            ctx.fill(Path(CGRect(x: x - 1, y: y - 1, width: 3, height: 3)),
                     with: .color(Color(red: 1.0, green: 1.0, blue: 0.5).opacity(pulse * 0.2)))
            // Core
            ctx.fill(Path(CGRect(x: x, y: y, width: 1, height: 1)),
                     with: .color(Color(red: 1.0, green: 0.95, blue: 0.4).opacity(pulse * 0.8)))

        case .autumn:
            // Falling leaves — rotation implied by alternating shape, drift + tumble
            let cycle = 6.0
            let phase = (time + seed).truncatingRemainder(dividingBy: cycle) / cycle
            let baseX = left + CGFloat((seed * 0.618).truncatingRemainder(dividingBy: 1.0)) * width
            let drift = CGFloat(sin(time * 0.9 + seed * 2.1)) * 10
            let x = baseX + drift
            let y = skyTop + CGFloat(phase) * skyH
            let alpha = 1.0 - abs(phase - 0.5) * 0.8
            let leafColors: [Color] = [
                Color(red: 0.8, green: 0.4, blue: 0.1),
                Color(red: 0.9, green: 0.5, blue: 0.15),
                Color(red: 0.7, green: 0.25, blue: 0.1),
            ]
            let color = leafColors[index % leafColors.count]
            // Tumbling leaf — swap width/height periodically
            let tumble = sin(time * 3.0 + seed)
            let w: CGFloat = tumble > 0 ? 2.5 : 1.5
            let h: CGFloat = tumble > 0 ? 1.5 : 2.5
            ctx.fill(Path(CGRect(x: x, y: y, width: w, height: h)),
                     with: .color(color.opacity(alpha * 0.75)))

        case .winter:
            // Snowflakes — slow descent, slight sway, varied sizes
            let cycle = 10.0  // slower than other particles
            let phase = (time + seed).truncatingRemainder(dividingBy: cycle) / cycle
            let baseX = left + CGFloat((seed * 0.618).truncatingRemainder(dividingBy: 1.0)) * width
            let sway = CGFloat(sin(time * 0.5 + seed)) * 4
            let x = baseX + sway
            let y = skyTop + CGFloat(phase) * skyH
            let alpha = 0.5 + 0.5 * (1.0 - abs(phase - 0.5) * 1.2)
            let sz: CGFloat = index % 3 == 0 ? 2 : 1  // some flakes larger
            ctx.fill(Path(CGRect(x: x, y: y, width: sz, height: sz)),
                     with: .color(Color.white.opacity(min(1, alpha) * 0.7)))
        }
    }

    /// Draw small seasonal accents on the ground near the grass line.
    static func drawSeasonalAccents(
        ctx: inout GraphicsContext, season: Season,
        grassX: CGFloat, grassY: CGFloat, grassWidth: CGFloat
    ) {
        var rng = StableRNG(seed: 99)

        switch season {
        case .spring:
            // Small flowers on the ground
            for _ in 0..<3 {
                let fx = grassX + CGFloat.random(in: 4...(grassWidth - 4), using: &rng)
                let fy = grassY - CGFloat.random(in: 1...4, using: &rng)
                let colors: [Color] = [
                    Color(red: 1.0, green: 0.6, blue: 0.7),
                    Color(red: 1.0, green: 0.9, blue: 0.3),
                    Color(red: 0.7, green: 0.6, blue: 1.0),
                ]
                let color = colors[Int.random(in: 0..<3, using: &rng)]
                ctx.fill(Path(CGRect(x: fx, y: fy, width: 1.5, height: 1.5)),
                         with: .color(color.opacity(0.8)))
            }

        case .summer:
            break  // fireflies are drawn as particles above

        case .autumn:
            // Small mushroom or pumpkin shapes at ground level
            for _ in 0..<2 {
                let mx = grassX + CGFloat.random(in: 8...(grassWidth - 8), using: &rng)
                let my = grassY - 1
                // Stem
                ctx.fill(Path(CGRect(x: mx + 0.5, y: my - 2, width: 1, height: 2)),
                         with: .color(Color(red: 0.7, green: 0.55, blue: 0.35).opacity(0.7)))
                // Cap
                ctx.fill(Path(CGRect(x: mx - 0.5, y: my - 3, width: 3, height: 1.5)),
                         with: .color(Color(red: 0.8, green: 0.3, blue: 0.15).opacity(0.7)))
            }

        case .winter:
            // Small snowdrift bumps on the grass line
            for _ in 0..<4 {
                let dx = grassX + CGFloat.random(in: 2...(grassWidth - 2), using: &rng)
                let dw = CGFloat.random(in: 3...6, using: &rng)
                ctx.fill(Path(CGRect(x: dx, y: grassY - 1, width: dw, height: 1.5)),
                         with: .color(Color.white.opacity(0.35)))
            }
        }
    }
}

// MARK: - Stable RNG

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
