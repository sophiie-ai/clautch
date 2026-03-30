import SwiftUI

/// Renders a single creature with animation driven by its state and type.
struct CreatureSpriteView: View {
    let state: CreatureState
    var creatureType: CreatureType = .ghost
    var colorPreset: CreatureColorPreset = .none

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 10)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let bob = BobAnimation.value(
                time: t,
                period: state.task.bobPeriod,
                amplitude: state.task.bobAmplitude
            )
            let frame = Int(t * state.task.fps) % max(creatureType.frames.count, 1)

            PixelCreatureView(
                type: creatureType,
                frame: frame,
                task: state.task,
                emotion: state.emotion,
                colorPreset: colorPreset
            )
            .frame(width: 32, height: 32)
            .offset(y: bob)
        }
    }
}

// MARK: - Generic Pixel Creature Renderer

/// Renders any creature type from its pixel grid data.
struct PixelCreatureView: View {
    let type: CreatureType
    let frame: Int
    let task: CreatureTask
    let emotion: CreatureEmotion
    var colorPreset: CreatureColorPreset = .none

    /// Body color adjusted for task state.
    private var bodyColor: Color {
        if let tint = colorPreset.tintColor {
            return tint.blended(with: taskTint, ratio: 0.3)
        }
        return type.baseColor.blended(with: taskTint, ratio: 0.3)
    }

    private var taskTint: Color {
        switch task {
        case .idle:       return .white
        case .working:    return Color(red: 0.6, green: 0.9, blue: 1.0)
        case .thinking:   return Color(red: 1.0, green: 0.9, blue: 0.6)
        case .sleeping:   return Color(white: 0.6)
        case .compacting: return Color(red: 1.0, green: 0.6, blue: 0.6)
        }
    }

    private var accentColor: Color {
        if let tint = colorPreset.tintColor {
            return tint.blended(with: type.accentColor, ratio: 0.5)
        }
        return type.accentColor
    }

    private var eyeColor: Color {
        task == .sleeping ? bodyColor : .black
    }

    private var mouthColor: Color {
        switch emotion {
        case .happy:   return Color(red: 0.2, green: 0.8, blue: 0.3)
        case .sad:     return Color(red: 0.3, green: 0.5, blue: 0.9)
        case .neutral: return bodyColor.opacity(0.7)
        }
    }

    private var highlightColor: Color {
        Color.white.opacity(0.6)
    }

    /// Resolve the grid for the current frame.
    private var grid: [[Int]] {
        let frames = type.frames
        guard !frames.isEmpty else { return [] }
        return frames[frame % frames.count]
    }

    var body: some View {
        Canvas { ctx, size in
            let grid = self.grid
            guard !grid.isEmpty else { return }
            let rows = grid.count
            let cols = grid.first?.count ?? 8
            let px = min(size.width / CGFloat(cols), size.height / CGFloat(rows))

            for (r, row) in grid.enumerated() {
                for (c, cell) in row.enumerated() {
                    guard cell != 0 else { continue }

                    let rect = CGRect(
                        x: CGFloat(c) * px,
                        y: CGFloat(r) * px,
                        width: px + 0.5,  // slight overlap to avoid gaps
                        height: px + 0.5
                    )

                    let color: Color = switch cell {
                    case 1: bodyColor
                    case 2: eyeColor
                    case 3: mouthColor
                    case 4: accentColor
                    case 5: highlightColor
                    default: bodyColor
                    }

                    ctx.fill(Path(rect), with: .color(color))
                }
            }

            // Sleeping indicator
            if task == .sleeping {
                let z = Text("z")
                    .font(.system(size: 6, weight: .bold))
                    .foregroundColor(.white)
                ctx.draw(ctx.resolve(z), at: CGPoint(x: size.width - 3, y: 3))
            }
        }
    }
}

// MARK: - Color Blending

extension Color {
    /// Simple blend: returns `self * (1 - ratio) + other * ratio`.
    func blended(with other: Color, ratio: Double) -> Color {
        let r = min(max(ratio, 0), 1)
        // Use NSColor for component extraction
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
