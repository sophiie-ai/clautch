import SwiftUI

/// Shared setting for reduced animation when panel is collapsed.
@Observable
final class AnimationSettings {
    static let shared = AnimationSettings()

    private static let reduceKey = "com.clautch.reduceAnimation"
    private static let hideKey = "com.clautch.hideWhenCollapsed"

    var reduceAnimationWhenCollapsed: Bool = false {
        didSet { UserDefaults.standard.set(reduceAnimationWhenCollapsed, forKey: Self.reduceKey) }
    }

    /// When enabled, nothing is shown below the notch until the user clicks on it.
    var hideWhenCollapsed: Bool = false {
        didSet { UserDefaults.standard.set(hideWhenCollapsed, forKey: Self.hideKey) }
    }

    /// When enabled, the notch panel is hidden and all processing is paused to save CPU.
    private static let pauseKey = "com.clautch.paused"
    var isPaused: Bool = false {
        didSet { UserDefaults.standard.set(isPaused, forKey: Self.pauseKey) }
    }

    /// Show status bar at the bottom of the expanded panel.
    private static let statusBarKey = "com.clautch.showStatusBar"
    var showStatusBar: Bool = true {
        didSet { UserDefaults.standard.set(showStatusBar, forKey: Self.statusBarKey) }
    }

    /// Show event log in the expanded panel.
    private static let eventLogKey = "com.clautch.showEventLog"
    var showEventLog: Bool = true {
        didSet { UserDefaults.standard.set(showEventLog, forKey: Self.eventLogKey) }
    }

    init() {
        self.reduceAnimationWhenCollapsed = UserDefaults.standard.bool(forKey: Self.reduceKey)
        self.hideWhenCollapsed = UserDefaults.standard.bool(forKey: Self.hideKey)
        self.isPaused = UserDefaults.standard.bool(forKey: Self.pauseKey)
        // Default to true for new settings
        self.showStatusBar = UserDefaults.standard.object(forKey: Self.statusBarKey) as? Bool ?? true
        self.showEventLog = UserDefaults.standard.object(forKey: Self.eventLogKey) as? Bool ?? true
    }
}

/// Renders a single creature with animation driven by its state and type.
struct CreatureSpriteView: View {
    let state: CreatureState
    var creatureType: CreatureType = .ghost
    var colorPreset: CreatureColorPreset = .none
    var accessory: CreatureAccessory = .none
    var evolution: CreatureEvolution = .baby
    var isExpanded: Bool = true
    var isWalking: Bool = false

    /// Per-creature seed for random collapsed animations (stable across frames).
    private var creatureSeed: Double {
        Double(creatureType.rawValue.utf8.reduce(0) { ($0 &* 31) &+ UInt64($1) } % 1000) / 100.0
    }

    private func collapsedAnimations(t: Double) -> (hop: CGFloat, tilt: Double) {
        let seed = creatureSeed
        let hopCycle = (t + seed * 3).truncatingRemainder(dividingBy: 5 + seed)
        let hop: CGFloat = hopCycle < 0.15 ? -2 : 0
        let tiltCycle = (t + seed * 7).truncatingRemainder(dividingBy: 7 + seed * 0.5)
        let tilt = tiltCycle > 6.5 ? sin(tiltCycle * 8) * 6 : 0
        return (hop, tilt)
    }

    var body: some View {
        let hidden = !isExpanded && AnimationSettings.shared.hideWhenCollapsed
        let reduced = !isExpanded && AnimationSettings.shared.reduceAnimationWhenCollapsed
        let interval: Double = isExpanded ? (1.0 / 10) : (reduced ? 2.0 : 1.0)

        TimelineView(hidden ? .animation(minimumInterval: 10) : .animation(minimumInterval: interval)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let bob = reduced ? 0.0 : BobAnimation.value(
                time: t,
                period: state.task.bobPeriod,
                amplitude: state.task.bobAmplitude
            )
            let walkHop: CGFloat = isWalking
                ? -3 * abs(CGFloat(sin(t * .pi * 4)))
                : 0
            let activeFrames = isWalking ? creatureType.walkFrames : creatureType.frames
            let frame = Int(t * (isWalking ? 6 : state.task.fps)) % max(activeFrames.count, 1)
            let collapsed = (!isExpanded && !isWalking && !reduced) ? collapsedAnimations(t: t) : (hop: CGFloat(0), tilt: 0.0)

            PixelCreatureView(
                type: creatureType,
                frame: frame,
                task: state.task,
                emotion: state.emotion,
                colorPreset: colorPreset,
                accessory: accessory,
                evolution: evolution,
                isWalking: isWalking,
                time: t,
                isExpanded: isExpanded
            )
            .frame(width: 32, height: 32)
            .offset(y: bob + walkHop + collapsed.hop)
            .rotationEffect(.degrees(collapsed.tilt))
            .scaleEffect(state.task == .compacting
                ? 0.85 + 0.15 * abs(sin(t * 4))
                : 1.0)
        }
    }
}

// MARK: - Generic Pixel Creature Renderer

/// Pre-computed color set for a creature, cached to avoid NSColor round-trips per frame.
private struct CreatureColors: Equatable {
    let body: Color
    let accent: Color
    let eye: Color
    let mouth: Color
    let highlight: Color

    /// Cache key to detect when colors need recomputing.
    struct Key: Hashable {
        let type: CreatureType
        let colorPreset: CreatureColorPreset
        let task: CreatureTask
        let emotion: CreatureEmotion
    }

    init(type: CreatureType, colorPreset: CreatureColorPreset, task: CreatureTask, emotion: CreatureEmotion) {
        let taskTint: Color = switch task {
        case .idle:       .white
        case .working:    Color(red: 0.6, green: 0.9, blue: 1.0)
        case .thinking:   Color(red: 1.0, green: 0.9, blue: 0.6)
        case .sleeping:   Color(white: 0.6)
        case .compacting: Color(red: 1.0, green: 0.6, blue: 0.6)
        }

        let baseBody: Color
        if let tint = colorPreset.tintColor {
            baseBody = tint.blended(with: taskTint, ratio: 0.3)
        } else {
            baseBody = type.baseColor.blended(with: taskTint, ratio: 0.3)
        }
        self.body = baseBody

        if let tint = colorPreset.tintColor {
            self.accent = tint.blended(with: type.accentColor, ratio: 0.5)
        } else {
            self.accent = type.accentColor
        }

        self.eye = task == .sleeping ? baseBody : .black

        self.mouth = switch emotion {
        case .happy, .excited: Color(red: 0.1, green: 0.9, blue: 0.2)
        case .sad:             Color(red: 0.3, green: 0.4, blue: 0.9)
        case .frustrated:      Color(red: 0.9, green: 0.2, blue: 0.1)
        case .confused:        Color(red: 0.8, green: 0.6, blue: 0.2)
        case .tired:           Color(red: 0.5, green: 0.5, blue: 0.6)
        case .neutral:         baseBody.opacity(0.7)
        }

        self.highlight = Color.white.opacity(0.6)
    }
}

/// Thread-safe cache for CreatureColors keyed by creature appearance.
/// Avoids per-frame NSColor↔sRGB round-trips.
private final class CreatureColorCache: @unchecked Sendable {
    static let shared = CreatureColorCache()
    private var cache: [CreatureColors.Key: CreatureColors] = [:]
    private let lock = NSLock()

    func colors(for key: CreatureColors.Key) -> CreatureColors {
        lock.lock()
        defer { lock.unlock() }
        if let cached = cache[key] { return cached }
        let colors = CreatureColors(type: key.type, colorPreset: key.colorPreset, task: key.task, emotion: key.emotion)
        cache[key] = colors
        // Cap cache size to prevent unbounded growth
        if cache.count > 64 { cache.removeAll() ; cache[key] = colors }
        return colors
    }
}

/// Renders any creature type from its pixel grid data with state-driven effects.
struct PixelCreatureView: View {
    let type: CreatureType
    let frame: Int
    let task: CreatureTask
    let emotion: CreatureEmotion
    var colorPreset: CreatureColorPreset = .none
    var accessory: CreatureAccessory = .none
    var evolution: CreatureEvolution = .baby
    var isWalking: Bool = false
    var time: Double = 0
    var isExpanded: Bool = true

    private var colors: CreatureColors {
        let key = CreatureColors.Key(type: type, colorPreset: colorPreset, task: task, emotion: emotion)
        return CreatureColorCache.shared.colors(for: key)
    }

    private var grid: [[Int]] {
        let frames = isWalking ? type.walkFrames : type.frames
        guard !frames.isEmpty else { return [] }
        return frames[frame % frames.count]
    }

    /// Whether the creature is blinking at this moment.
    private var isBlinking: Bool {
        // Blink every ~3.5 seconds for 0.15 seconds (pseudorandom per creature type)
        let period = 3.5 + Double(type.rawValue.count) * 0.3
        let cycle = time.truncatingRemainder(dividingBy: period)
        return cycle < 0.15
    }

    var body: some View {
        let colors = self.colors
        let blinking = isBlinking && task != .sleeping
        Canvas { ctx, size in
            let grid = self.grid
            guard !grid.isEmpty else { return }
            let rows = grid.count
            let cols = grid.first?.count ?? 8
            let px = min(size.width / CGFloat(cols), size.height / CGFloat(rows))

            // --- Main grid ---
            for (r, row) in grid.enumerated() {
                for (c, cell) in row.enumerated() {
                    guard cell != 0 else { continue }
                    let rect = CGRect(
                        x: CGFloat(c) * px, y: CGFloat(r) * px,
                        width: px + 0.5, height: px + 0.5
                    )
                    let color: Color = switch cell {
                    case 1: colors.body
                    case 2: blinking ? colors.body : colors.eye  // blink: eyes match body
                    case 3: colors.mouth
                    case 4: colors.accent
                    case 5: colors.highlight
                    default: colors.body
                    }
                    ctx.fill(Path(rect), with: .color(color))
                }
            }

            // --- Accessory overlay ---
            if let accPixels = accessory.pixels {
                let accRows = accPixels.count
                let accCols = accPixels.first?.count ?? 4
                let accPx = px
                // Center horizontally, position above the creature head
                let offsetX = (CGFloat(cols) - CGFloat(accCols)) / 2 * accPx
                let offsetY = -CGFloat(accRows) * accPx + accPx * 0.5
                for (r, row) in accPixels.enumerated() {
                    for (c, cell) in row.enumerated() {
                        guard cell != 0 else { continue }
                        let rect = CGRect(
                            x: offsetX + CGFloat(c) * accPx,
                            y: offsetY + CGFloat(r) * accPx,
                            width: accPx + 0.5, height: accPx + 0.5
                        )
                        let color = cell == 6 ? accessory.primaryColor : accessory.secondaryColor
                        ctx.fill(Path(rect), with: .color(color))
                    }
                }
            }

            // --- Evolution glow (grown/elder) ---
            if evolution >= .grown {
                drawEvolutionEffects(ctx: ctx, size: size, px: px)
            }

            // --- State effects (expanded only) ---
            if isExpanded {
                drawStateEffects(ctx: ctx, size: size, px: px)
            }
        }
    }

    // MARK: - Evolution Effects

    private func drawEvolutionEffects(ctx: GraphicsContext, size: CGSize, px: CGFloat) {
        let t = time
        let midX = size.width / 2
        let midY = size.height / 2

        // Soft glow aura
        let glowColor = evolution.glowColor
        let radius = evolution.glowRadius
        let pulse = 0.4 + 0.6 * abs(sin(t * 1.2))
        ctx.fill(
            Path(ellipseIn: CGRect(
                x: midX - size.width / 2 - radius,
                y: midY - size.height / 2 - radius,
                width: size.width + radius * 2,
                height: size.height + radius * 2
            )),
            with: .color(glowColor.opacity(0.12 * pulse))
        )

        // Elder: orbiting sparkle particles
        if evolution == .elder {
            let sparkles = 4
            for i in 0..<sparkles {
                let angle = t * 1.5 + Double(i) * (.pi * 2 / Double(sparkles))
                let orbitX = midX + cos(angle) * (size.width / 2 + 2)
                let orbitY = midY + sin(angle) * (size.height / 2 + 1)
                let twinkle = abs(sin(t * 4 + Double(i) * 1.5))
                let s: CGFloat = 1.5
                ctx.fill(
                    Path(CGRect(x: orbitX - s / 2, y: orbitY - s / 2, width: s, height: s)),
                    with: .color(Color(red: 1.0, green: 0.95, blue: 0.5).opacity(twinkle * 0.7))
                )
            }
        }
    }

    // MARK: - State Effects

    private func drawStateEffects(ctx: GraphicsContext, size: CGSize, px: CGFloat) {
        let t = time

        // Sleeping: animated "z" particles floating upward
        if task == .sleeping {
            let zSpecs: [(dx: CGFloat, delay: Double, baseSize: CGFloat)] = [
                (4, 0.0, 5), (6, 0.8, 6), (3, 1.6, 7),
            ]
            for z in zSpecs {
                let cycle = (t + z.delay).truncatingRemainder(dividingBy: 2.5)
                let progress = cycle / 2.5
                let alpha = 1.0 - progress
                let yOff = progress * 12
                let resolved = ctx.resolve(
                    Text("z")
                        .font(.system(size: z.baseSize + progress * 2, weight: .bold))
                        .foregroundColor(.white.opacity(alpha))
                )
                ctx.draw(resolved, at: CGPoint(
                    x: size.width - z.dx,
                    y: 8 - yOff
                ))
            }
        }

        // Thinking: pulsing dots above creature
        if task == .thinking {
            let dotR: CGFloat = 1.5
            let baseY: CGFloat = 1
            let midX = size.width / 2
            for i in 0..<3 {
                let phase = (t * 2 + Double(i) * 0.4)
                    .truncatingRemainder(dividingBy: 1.0)
                let alpha = 0.3 + 0.7 * abs(sin(phase * .pi))
                let yOff = -1.5 * sin(phase * .pi)
                ctx.fill(
                    Path(ellipseIn: CGRect(
                        x: midX + CGFloat(i - 1) * 4 - dotR,
                        y: baseY + CGFloat(yOff) - dotR,
                        width: dotR * 2, height: dotR * 2
                    )),
                    with: .color(.yellow.opacity(alpha))
                )
            }
        }

        // Working: sparkle particles
        if task == .working {
            let sparkles: [(dx: CGFloat, dy: CGFloat, d: Double)] = [
                (2, 2, 0.0), (-3, 5, 0.3), (5, -1, 0.6),
                (-2, -3, 0.9), (4, 6, 1.2),
            ]
            for sp in sparkles {
                let cycle = (t * 3 + sp.d).truncatingRemainder(dividingBy: 1.0)
                let alpha = cycle < 0.5 ? cycle * 2 : (1 - cycle) * 2
                let s: CGFloat = 1.5
                ctx.fill(
                    Path(CGRect(
                        x: size.width / 2 + sp.dx * 3 - s / 2,
                        y: size.height / 2 + sp.dy * 2 - s / 2,
                        width: s, height: s
                    )),
                    with: .color(.cyan.opacity(alpha * 0.8))
                )
            }
        }

        // Compacting: blinking warning "!"
        if task == .compacting {
            let blink = abs(sin(t * 4))
            let resolved = ctx.resolve(
                Text("!")
                    .font(.system(size: 7, weight: .heavy))
                    .foregroundColor(.red.opacity(blink))
            )
            ctx.draw(resolved, at: CGPoint(x: size.width - 3, y: 4))
        }

        // Happy: sparkle near face
        if emotion == .happy {
            let twinkle = abs(sin(t * 3))
            ctx.fill(
                Path(CGRect(x: size.width - 5, y: 4, width: 2, height: 2)),
                with: .color(.yellow.opacity(twinkle * 0.7))
            )
        }

        // Sad: animated tear
        if emotion == .sad {
            let cycle = t.truncatingRemainder(dividingBy: 1.5)
            let progress = cycle / 1.5
            let alpha = 1.0 - progress
            if alpha > 0 {
                let tearY = 3 * px + progress * 3 * px
                ctx.fill(
                    Path(ellipseIn: CGRect(
                        x: 2 * px + 0.5, y: tearY,
                        width: px * 0.6, height: px * 0.8
                    )),
                    with: .color(Color(red: 0.4, green: 0.6, blue: 1.0).opacity(alpha))
                )
            }
        }

        // Frustrated: angry steam puffs rising from top
        if emotion == .frustrated {
            let puffs: [(dx: CGFloat, delay: Double)] = [(-2, 0.0), (2, 0.5), (0, 1.0)]
            for puff in puffs {
                let cycle = (t * 1.5 + puff.delay).truncatingRemainder(dividingBy: 2.0)
                let progress = cycle / 2.0
                let alpha = (1.0 - progress) * 0.6
                let yOff = progress * 8
                let s: CGFloat = 2 + progress * 1.5
                ctx.fill(
                    Path(ellipseIn: CGRect(
                        x: size.width / 2 + puff.dx * 3 - s / 2,
                        y: 2 - yOff,
                        width: s, height: s
                    )),
                    with: .color(Color.red.opacity(alpha))
                )
            }
        }

        // Excited: bouncing stars around creature
        if emotion == .excited {
            let stars: [(dx: CGFloat, dy: CGFloat, d: Double)] = [
                (4, -2, 0.0), (-4, 0, 0.3), (3, 3, 0.6), (-3, -3, 0.9),
            ]
            for star in stars {
                let cycle = (t * 4 + star.d).truncatingRemainder(dividingBy: 1.0)
                let alpha = cycle < 0.5 ? cycle * 2 : (1 - cycle) * 2
                let s: CGFloat = 2
                ctx.fill(
                    Path(CGRect(
                        x: size.width / 2 + star.dx * 2 - s / 2,
                        y: size.height / 2 + star.dy * 2 - s / 2,
                        width: s, height: s
                    )),
                    with: .color(.yellow.opacity(alpha * 0.9))
                )
            }
        }

        // Confused: spinning "?" above head
        if emotion == .confused {
            let bob = sin(t * 3) * 2
            let resolved = ctx.resolve(
                Text("?")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.yellow.opacity(0.8))
            )
            ctx.draw(resolved, at: CGPoint(x: size.width / 2 + 5, y: 4 + bob))
        }

        // Tired: droopy eyes effect (slower blink) + sweat drop
        if emotion == .tired {
            let sweatCycle = t.truncatingRemainder(dividingBy: 3.0)
            let progress = sweatCycle / 3.0
            let alpha = 1.0 - progress
            if alpha > 0.2 {
                let dropY = 2 * px + progress * 4 * px
                ctx.fill(
                    Path(ellipseIn: CGRect(
                        x: size.width - 3, y: dropY,
                        width: px * 0.5, height: px * 0.7
                    )),
                    with: .color(Color(red: 0.5, green: 0.7, blue: 1.0).opacity(alpha * 0.6))
                )
            }
        }

        // Idle personality animations: unique per creature type
        if task == .idle && emotion == .neutral {
            drawPersonalityEffect(ctx: ctx, size: size, px: px, t: t)
        }
    }
    // MARK: - Personality Effects

    /// Each creature type has a unique idle micro-animation.
    private func drawPersonalityEffect(ctx: GraphicsContext, size: CGSize, px: CGFloat, t: Double) {
        let cycle = t.truncatingRemainder(dividingBy: 10.0)

        switch type {
        case .cat:
            // Cat grooms: paw reaches to face (3-4s in cycle)
            if cycle > 3.0 && cycle < 4.0 {
                let progress = sin((cycle - 3.0) * .pi)
                ctx.fill(
                    Path(CGRect(x: size.width / 2 + 2, y: 4 * px - progress * 2, width: px, height: px)),
                    with: .color(colors.body.opacity(progress * 0.8))
                )
            }

        case .owl:
            // Owl turns head: eyes shift dramatically (2-3.5s)
            if cycle > 2.0 && cycle < 3.5 {
                let progress = (cycle - 2.0) / 1.5
                let shift = sin(progress * .pi * 2) * 2.5
                ctx.fill(
                    Path(CGRect(x: size.width / 2 + shift - 0.5, y: 3 * px, width: 1.5, height: 1)),
                    with: .color(.white.opacity(0.6))
                )
            }

        case .mushroom:
            // Mushroom bounces: squash and stretch (6-7s)
            // Handled via the main bounce, but add a spore particle
            if cycle > 6.0 && cycle < 7.0 {
                let progress = (cycle - 6.0) / 1.0
                let alpha = sin(progress * .pi) * 0.5
                for i in 0..<3 {
                    let dx = CGFloat(i - 1) * 3
                    let dy = progress * 6
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: size.width / 2 + dx - 0.5, y: 1 - dy, width: 1, height: 1)),
                        with: .color(.green.opacity(alpha))
                    )
                }
            }

        case .robot:
            // Robot antenna flash (4-5s)
            if cycle > 4.0 && cycle < 5.0 {
                let blink = abs(sin((cycle - 4.0) * .pi * 4))
                ctx.fill(
                    Path(ellipseIn: CGRect(x: size.width / 2 - 1, y: 0, width: 2, height: 2)),
                    with: .color(.cyan.opacity(blink * 0.7))
                )
            }

        case .slime:
            // Slime jiggles: wobbly outline (7-8.5s)
            if cycle > 7.0 && cycle < 8.5 {
                let wobble = sin((cycle - 7.0) * .pi * 3) * 1.5
                ctx.fill(
                    Path(ellipseIn: CGRect(
                        x: size.width / 2 - 3 + wobble, y: size.height - 3 * px,
                        width: 6, height: 2
                    )),
                    with: .color(colors.body.opacity(0.3))
                )
            }

        case .ghost:
            // Ghost phases: opacity flicker (5-6s)
            if cycle > 5.0 && cycle < 6.0 {
                let flicker = abs(sin((cycle - 5.0) * .pi * 6))
                ctx.fill(
                    Path(CGRect(x: 0, y: 0, width: size.width, height: size.height)),
                    with: .color(.white.opacity(flicker * 0.08))
                )
            }
        }

        // Common: look-around eyes (shared, but at different times per type)
        let lookCycle = (t + Double(type.rawValue.count) * 2).truncatingRemainder(dividingBy: 12.0)
        if lookCycle > 2.0 && lookCycle < 3.0 {
            let shift = sin((lookCycle - 2.0) * .pi) * 1.5
            ctx.fill(
                Path(CGRect(x: size.width / 2 + shift - 0.5, y: 3 * px, width: 1, height: 1)),
                with: .color(.white.opacity(0.5))
            )
        }
    }
}

// MARK: - Color Blending

extension Color {
    func blended(with other: Color, ratio: Double) -> Color {
        let r = min(max(ratio, 0), 1)
        guard let c1 = NSColor(self).usingColorSpace(.sRGB),
              let c2 = NSColor(other).usingColorSpace(.sRGB) else { return self }
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(
            red: r1 * (1 - r) + r2 * r,
            green: g1 * (1 - r) + g2 * r,
            blue: b1 * (1 - r) + b2 * r
        )
    }
}
