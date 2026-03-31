import SwiftUI

/// Shared setting for reduced animation when panel is collapsed.
@Observable
final class AnimationSettings {
    static let shared = AnimationSettings()

    private static let persistenceKey = "com.clautch.reduceAnimation"

    var reduceAnimationWhenCollapsed: Bool = false {
        didSet {
            UserDefaults.standard.set(reduceAnimationWhenCollapsed, forKey: Self.persistenceKey)
        }
    }

    init() {
        self.reduceAnimationWhenCollapsed = UserDefaults.standard.bool(forKey: Self.persistenceKey)
    }
}

/// Renders a single creature with animation driven by its state and type.
struct CreatureSpriteView: View {
    let state: CreatureState
    var creatureType: CreatureType = .ghost
    var colorPreset: CreatureColorPreset = .none
    var accessory: CreatureAccessory = .none
    var isExpanded: Bool = true
    var isWalking: Bool = false

    var body: some View {
        let shouldAnimate = isExpanded || !AnimationSettings.shared.reduceAnimationWhenCollapsed
        let interval: Double = shouldAnimate ? (1.0 / 10) : (1.0 / 2)

        TimelineView(.animation(minimumInterval: interval)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let bob = BobAnimation.value(
                time: t,
                period: state.task.bobPeriod,
                amplitude: state.task.bobAmplitude
            )
            let activeFrames = isWalking ? creatureType.walkFrames : creatureType.frames
            let frame = Int(t * (isWalking ? 6 : state.task.fps)) % max(activeFrames.count, 1)

            PixelCreatureView(
                type: creatureType,
                frame: frame,
                task: state.task,
                emotion: state.emotion,
                colorPreset: colorPreset,
                accessory: accessory,
                isWalking: isWalking,
                time: t
            )
            .frame(width: 32, height: 32)
            .offset(y: bob)
            // Compacting: pulsing scale
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
        case .happy:   Color(red: 0.1, green: 0.9, blue: 0.2)
        case .sad:     Color(red: 0.3, green: 0.4, blue: 0.9)
        case .neutral: baseBody.opacity(0.7)
        }

        self.highlight = Color.white.opacity(0.6)
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
    var isWalking: Bool = false
    var time: Double = 0

    private var colors: CreatureColors {
        CreatureColors(type: type, colorPreset: colorPreset, task: task, emotion: emotion)
    }

    private var grid: [[Int]] {
        let frames = isWalking ? type.walkFrames : type.frames
        guard !frames.isEmpty else { return [] }
        return frames[frame % frames.count]
    }

    var body: some View {
        let colors = self.colors
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
                    case 2: colors.eye
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

            // --- State effects ---
            drawStateEffects(ctx: ctx, size: size, px: px)
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
