import SwiftUI

/// Renders a Dynamic-Island-style panel extending from the notch.
/// Collapsed: small bump with creature head peeking out.
/// Expanded on hover: full panel with creature on grass.
struct GrassIslandView: View {
    let creatures: [CreatureDisplay]
    var isExpanded: Bool = false

    @State private var bounceScale: CGFloat = 1.0
    @State private var bounceOffset: CGFloat = 0

    private var creatureSize: CGFloat {
        switch creatures.count {
        case 0...3: return 32
        case 4:     return 28
        case 5:     return 24
        default:    return 20
        }
    }

    var body: some View {
        let screen = NSScreen.screens.first(where: { $0.hasNotch })
        let notchHeight = screen?.safeAreaInsets.top ?? 32

        Canvas { ctx, size in
            let notchWidth = notchWidthInWindow(totalWidth: size.width)
            let maxDrop = size.height - notchHeight
            let peekDrop: CGFloat = 16
            let dropHeight = isExpanded ? maxDrop : peekDrop
            let midX = size.width / 2
            let notchHalf = notchWidth / 2
            let expandedPanelHalf = min(size.width / 2 - 2, notchHalf + 30)
            // Collapsed: notch width + horizontal padding. Expanded: wider panel.
            let panelHalf = isExpanded ? expandedPanelHalf : notchHalf + 20
            let bottom = notchHeight + dropHeight
            let r: CGFloat = isExpanded ? 18 : 6
            let cr = min(r, dropHeight / 2)

            // 1. Draw island shape
            var path = Path()
            path.move(to: CGPoint(x: midX - notchHalf, y: 0))
            path.addLine(to: CGPoint(x: midX + notchHalf, y: 0))

            if isExpanded {
                // Expanded: curves from notch out to wider panel
                path.addCurve(
                    to: CGPoint(x: midX + panelHalf, y: notchHeight + cr),
                    control1: CGPoint(x: midX + notchHalf, y: notchHeight),
                    control2: CGPoint(x: midX + panelHalf, y: notchHeight)
                )
            } else {
                // Collapsed: straight down from notch, then angle out to panel width
                path.addLine(to: CGPoint(x: midX + notchHalf, y: notchHeight))
                path.addQuadCurve(
                    to: CGPoint(x: midX + panelHalf, y: notchHeight + 4),
                    control: CGPoint(x: midX + panelHalf, y: notchHeight)
                )
            }

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

            if isExpanded {
                path.addLine(to: CGPoint(x: midX - panelHalf, y: notchHeight + cr))
                path.addCurve(
                    to: CGPoint(x: midX - notchHalf, y: 0),
                    control1: CGPoint(x: midX - panelHalf, y: notchHeight),
                    control2: CGPoint(x: midX - notchHalf, y: notchHeight)
                )
            } else {
                path.addLine(to: CGPoint(x: midX - panelHalf, y: notchHeight + 4))
                path.addQuadCurve(
                    to: CGPoint(x: midX - notchHalf, y: notchHeight),
                    control: CGPoint(x: midX - panelHalf, y: notchHeight)
                )
                path.addLine(to: CGPoint(x: midX - notchHalf, y: 0))
            }

            path.closeSubpath()
            ctx.fill(path, with: .color(.black))

            // 2. Draw grass at bottom of island
            let grassY = bottom - 10
            let grassWidth = panelHalf * 2 - 16
            let grassX = midX - grassWidth / 2
            let darkGreen = Color(red: 0.18, green: 0.5, blue: 0.22)
            let green = Color(red: 0.25, green: 0.65, blue: 0.3)
            ctx.fill(Path(CGRect(x: grassX, y: bottom - 5, width: grassWidth, height: 5)),
                     with: .color(darkGreen))
            var rng = StableRNG(seed: 42)
            let bladeCount = Int(grassWidth / 3)
            for i in 0..<bladeCount {
                let bx = grassX + CGFloat(i) * 3 + CGFloat.random(in: -1...1, using: &rng)
                let h = CGFloat.random(in: 3...8, using: &rng)
                let rect = CGRect(x: bx, y: bottom - h, width: 2, height: h)
                let opacity = Double.random(in: 0.5...1.0, using: &rng)
                ctx.fill(Path(rect), with: .color(green.opacity(opacity)))
            }

            // 3. Draw creatures
            // We can't draw SwiftUI views in Canvas, so draw simple pixel eyes
            // as a placeholder. The real creature is overlaid separately.
        }
        .overlay {
            // SwiftUI creature sprites positioned absolutely
            GeometryReader { geo in
                let maxDrop = geo.size.height - notchHeight
                let peekDrop: CGFloat = 8
                let dropHeight = isExpanded ? maxDrop : peekDrop
                let bottom = notchHeight + dropHeight

                ForEach(creatures.sorted(by: { $0.xPosition < $1.xPosition })) { creature in
                    VStack(spacing: 2) {
                        // Task + tool label (expanded only)
                        if isExpanded && creature.sessionDuration != nil {
                            VStack(spacing: 1) {
                                Text(creature.state.task.displayLabel)
                                    .font(.system(size: 7, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.6))
                                if let tool = creature.lastToolName {
                                    Text(tool)
                                        .font(.system(size: 6, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.35))
                                }
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                        }

                        CreatureSpriteView(
                            state: creature.state,
                            creatureType: creature.creatureType,
                            colorPreset: creature.colorPreset,
                            isExpanded: isExpanded
                        )
                        .frame(width: creatureSize, height: creatureSize)
                        .scaleEffect(x: creature.facingRight ? 1 : -1, y: 1)
                        // Squash-stretch on landing
                        .scaleEffect(
                            x: 1 + (1 - bounceScale) * 0.5,
                            y: bounceScale,
                            anchor: .bottom
                        )
                        .offset(y: bounceOffset)

                        // Session duration (expanded only)
                        if isExpanded, let duration = creature.sessionDuration {
                            Text(formatDuration(duration))
                                .font(.system(size: 6, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.4))
                                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                        }
                    }
                    .position(
                        x: geo.size.width / 2 + creatureOffset(for: creature, in: geo.size.width),
                        y: bottom - creatureSize / 2 - 8
                    )
                    .shadow(
                        color: creature.isLocal ? .white.opacity(0.2) : .clear,
                        radius: creature.isLocal ? 3 : 0
                    )
                    .help(creature.id == "local-idle"
                        ? "Idle"
                        : "\(creature.displayName): \(creature.state.task.displayLabel)")
                }
            }
        }
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

    /// Squash on impact, then spring back with overshoot.
    private func triggerLandingBounce() {
        // Wait for the panel expansion to mostly finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            // Squash: compress vertically, shift down
            withAnimation(.easeIn(duration: 0.08)) {
                bounceScale = 0.7
                bounceOffset = 4
            }
            // Spring back with overshoot
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.35)) {
                    bounceScale = 1.0
                    bounceOffset = 0
                }
            }
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let m = Int(interval) / 60
        let s = Int(interval) % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    private func creatureOffset(for creature: CreatureDisplay, in width: CGFloat) -> CGFloat {
        let usable = width - creatureSize - 20
        return -usable / 2 + creature.xPosition * usable
    }

    private func notchWidthInWindow(totalWidth: CGFloat) -> CGFloat {
        guard let screen = NSScreen.screens.first(where: { $0.hasNotch }),
              let notch = screen.notchSize,
              let win = screen.notchWindowFrame else { return totalWidth * 0.7 }
        return notch.width * totalWidth / win.width
    }
}

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

// Keep GrassPatchView for other uses
struct GrassPatchView: View {
    var body: some View {
        Canvas { ctx, size in
            let green = Color(red: 0.25, green: 0.65, blue: 0.3)
            let darkGreen = Color(red: 0.18, green: 0.5, blue: 0.22)
            ctx.fill(Path(CGRect(x: 0, y: size.height / 2, width: size.width, height: size.height / 2)),
                     with: .color(darkGreen))
            var rng = StableRNG(seed: 42)
            let bladeCount = Int(size.width / 3)
            for i in 0..<bladeCount {
                let x = CGFloat(i) * 3 + CGFloat.random(in: -1...1, using: &rng)
                let h = CGFloat.random(in: 3...8, using: &rng)
                let rect = CGRect(x: x, y: size.height - h, width: 2, height: h)
                let opacity = Double.random(in: 0.5...1.0, using: &rng)
                ctx.fill(Path(rect), with: .color(green.opacity(opacity)))
            }
        }
    }
}
