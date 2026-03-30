import SwiftUI

/// Renders a grass island with creatures standing on it.
/// Accepts a unified list of local + remote creatures.
struct GrassIslandView: View {
    let creatures: [CreatureDisplay]

    /// Scale down creatures when there are many to fit in the notch.
    private var creatureSize: CGFloat {
        switch creatures.count {
        case 0...3: return 32
        case 4:     return 28
        case 5:     return 24
        default:    return 20
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Grass base
                GrassPatchView()
                    .frame(height: 10)
                    .frame(maxWidth: .infinity)

                // Creatures sorted by x position for consistent layering
                let sorted = creatures.sorted { $0.xPosition < $1.xPosition }
                ForEach(sorted) { creature in
                    VStack(spacing: 1) {
                        CreatureSpriteView(
                            state: creature.state,
                            creatureType: creature.creatureType,
                            colorPreset: creature.colorPreset
                        )
                        .frame(width: creatureSize, height: creatureSize)

                        // Name label for remote peers
                        if !creature.isLocal && creatures.count > 1 {
                            Text(creature.displayName)
                                .font(.system(size: 6, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                    }
                    .offset(
                        x: (creature.xPosition - 0.5) * geo.size.width * 0.6,
                        y: -10
                    )
                    // Subtle glow for local creature
                    .shadow(
                        color: creature.isLocal ? .white.opacity(0.3) : .clear,
                        radius: creature.isLocal ? 3 : 0
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
}

// MARK: - Grass

struct GrassPatchView: View {
    var body: some View {
        Canvas { ctx, size in
            let green = Color(red: 0.25, green: 0.65, blue: 0.3)
            let darkGreen = Color(red: 0.18, green: 0.5, blue: 0.22)

            // Base ground
            ctx.fill(
                Path(CGRect(x: 0, y: size.height / 2, width: size.width, height: size.height / 2)),
                with: .color(darkGreen)
            )

            // Grass blades
            var rng = StableRNG(seed: 42)
            let bladeCount = Int(size.width / 3)
            for i in 0..<bladeCount {
                let x = CGFloat(i) * 3 + CGFloat.random(in: -1...1, using: &rng)
                let h = CGFloat.random(in: 3...8, using: &rng)
                let w: CGFloat = 2
                let rect = CGRect(x: x, y: size.height - h, width: w, height: h)
                let opacity = Double.random(in: 0.5...1.0, using: &rng)
                ctx.fill(Path(rect), with: .color(green.opacity(opacity)))
            }
        }
    }
}

/// Deterministic RNG so grass doesn't re-randomize every frame.
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
