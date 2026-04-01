import SwiftUI

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
        switch creatures.count {
        case 0...3: return 32
        case 4:     return 28
        case 5:     return 24
        default:    return 20
        }
    }

    private let skyTop = Color(red: 0.15, green: 0.25, blue: 0.45)
    private let skyBottom = Color(red: 0.25, green: 0.45, blue: 0.55)
    private let grassGreen = Color(red: 0.2, green: 0.5, blue: 0.25)
    private let grassDark = Color(red: 0.12, green: 0.35, blue: 0.15)

    var body: some View {
        let screen = NSScreen.screens.first(where: { $0.hasNotch })
        let notchHeight = screen?.safeAreaInsets.top ?? 32
        let showLog = AnimationSettings.shared.showEventLog && isExpanded
        let showStatus = AnimationSettings.shared.showStatusBar && isExpanded

        Canvas { ctx, size in
            let notchWidth = notchWidthInWindow(totalWidth: size.width)
            let maxDrop = size.height - notchHeight
            let hideWhenCollapsed = AnimationSettings.shared.hideWhenCollapsed
            let peekDrop: CGFloat = hideWhenCollapsed ? 0 : 16
            let dropHeight = isExpanded ? maxDrop : peekDrop
            let midX = size.width / 2
            let notchHalf = notchWidth / 2
            let expandedPanelHalf = min(size.width / 2 - 2, notchHalf + 50)
            let panelHalf = isExpanded ? expandedPanelHalf : notchHalf + 20
            let bottom = notchHeight + dropHeight
            let r: CGFloat = isExpanded ? 18 : 6
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
                // Collapsed: notch-hugging bump
                path.move(to: CGPoint(x: midX - notchHalf, y: 0))
                path.addLine(to: CGPoint(x: midX + notchHalf, y: 0))
                path.addLine(to: CGPoint(x: midX + notchHalf, y: notchHeight))
                path.addQuadCurve(
                    to: CGPoint(x: midX + panelHalf, y: notchHeight + 4),
                    control: CGPoint(x: midX + panelHalf, y: notchHeight)
                )
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
                path.addLine(to: CGPoint(x: midX - panelHalf, y: notchHeight + 4))
                path.addQuadCurve(
                    to: CGPoint(x: midX - notchHalf, y: notchHeight),
                    control: CGPoint(x: midX - panelHalf, y: notchHeight)
                )
                path.addLine(to: CGPoint(x: midX - notchHalf, y: 0))
            }
            path.closeSubpath()

            if isExpanded {
                // 2. Draw scenic background
                let grassY = (bottom) * 0.4

                // Sky gradient (fills from top of screen)
                ctx.clip(to: path)
                let skyGradient = Gradient(colors: [skyTop, skyBottom])
                ctx.fill(
                    Path(CGRect(x: midX - panelHalf, y: 0, width: panelHalf * 2, height: grassY)),
                    with: .linearGradient(skyGradient, startPoint: CGPoint(x: midX, y: 0), endPoint: CGPoint(x: midX, y: grassY))
                )

                // Stars (tiny dots in sky)
                var starRng = StableRNG(seed: 77)
                for _ in 0..<12 {
                    let sx = midX - panelHalf + CGFloat.random(in: 0...(panelHalf * 2), using: &starRng)
                    let sy = CGFloat.random(in: notchHeight + 5...grassY - 5, using: &starRng)
                    let alpha = Double.random(in: 0.3...0.7, using: &starRng)
                    ctx.fill(Path(CGRect(x: sx, y: sy, width: 1, height: 1)), with: .color(.white.opacity(alpha)))
                }

                // Ground
                ctx.fill(
                    Path(CGRect(x: midX - panelHalf, y: grassY, width: panelHalf * 2, height: bottom - grassY)),
                    with: .color(grassDark)
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
                    ctx.fill(Path(rect), with: .color(grassGreen.opacity(opacity)))
                }

                // Dark section below for event log
                if showLog {
                    let logY = grassY + 20
                    ctx.fill(
                        Path(CGRect(x: midX - panelHalf, y: logY, width: panelHalf * 2, height: bottom - logY)),
                        with: .color(Color.black.opacity(0.85))
                    )
                    // Divider line
                    ctx.fill(
                        Path(CGRect(x: midX - panelHalf + 8, y: logY, width: panelHalf * 2 - 16, height: 0.5)),
                        with: .color(.white.opacity(0.1))
                    )
                }
            } else {
                // Collapsed: simple black
                ctx.fill(path, with: .color(.black))

                // Small grass strip
                let grassWidth = panelHalf * 2 - 16
                let grassX = midX - grassWidth / 2
                let bottom = notchHeight + (AnimationSettings.shared.hideWhenCollapsed ? 0 : 16)
                ctx.fill(Path(CGRect(x: grassX, y: bottom - 5, width: grassWidth, height: 5)),
                         with: .color(grassDark))
                var rng = StableRNG(seed: 42)
                let bladeCount = Int(grassWidth / 3)
                for i in 0..<bladeCount {
                    let bx = grassX + CGFloat(i) * 3 + CGFloat.random(in: -1...1, using: &rng)
                    let h = CGFloat.random(in: 3...8, using: &rng)
                    let rect = CGRect(x: bx, y: bottom - h, width: 2, height: h)
                    let opacity = Double.random(in: 0.5...1.0, using: &rng)
                    ctx.fill(Path(rect), with: .color(grassGreen.opacity(opacity)))
                }
            }
        }
        .overlay {
            // SwiftUI creature sprites
            GeometryReader { geo in
                let maxDrop = geo.size.height - notchHeight
                let hideWhenCollapsed = AnimationSettings.shared.hideWhenCollapsed
                let peekDrop: CGFloat = hideWhenCollapsed ? 0 : 8
                let dropHeight = isExpanded ? maxDrop : peekDrop
                // Creatures sit on the grass line (40% of total height)
                let grassLineY = isExpanded
                    ? geo.size.height * 0.4
                    : notchHeight + dropHeight

                ForEach(creatures.sorted(by: { $0.xPosition < $1.xPosition })) { creature in
                    TimelineView(.animation(minimumInterval: 1.0 / 12)) { timeline in
                        let t = timeline.date.timeIntervalSinceReferenceDate
                        let walkHop: CGFloat = (isWalking && creature.isLocal)
                            ? -3 * abs(CGFloat(sin(t * .pi * 4)))
                            : 0

                        CreatureSpriteView(
                            state: creature.state,
                            creatureType: creature.creatureType,
                            colorPreset: creature.colorPreset,
                            accessory: creature.accessory,
                            isExpanded: isExpanded,
                            isWalking: isWalking && creature.isLocal
                        )
                        .frame(width: creatureSize, height: creatureSize)
                        .scaleEffect(x: creature.facingRight ? 1 : -1, y: 1)
                        .scaleEffect(
                            x: 1 + (1 - bounceScale) * 0.5,
                            y: bounceScale,
                            anchor: .bottom
                        )
                        .offset(y: bounceOffset + walkHop)
                    }
                    .overlay(alignment: .top) {
                        VStack(spacing: 2) {
                            if isExpanded, let chat = creature.chatMessage {
                                Text(String(chat.prefix(50)))
                                    .font(.system(size: 7, weight: .medium, design: .rounded))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(.white.opacity(0.9))
                                    )
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.5).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                                    .id("chat-\(creature.id)-\(chat)")
                            }

                            if let reaction = creature.reaction {
                                PixelReactionView(reaction: reaction)
                                    .frame(width: 15, height: 15)
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.3).combined(with: .opacity).combined(with: .offset(y: 4)),
                                        removal: .opacity.combined(with: .offset(y: -6))
                                    ))
                                    .id("reaction-\(creature.id)-\(reaction.rawValue)")
                            }

                            if isExpanded && creature.isLocal {
                                Text(creature.state.task.displayLabel)
                                    .font(.system(size: 7, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .transition(.opacity)
                            }
                        }
                        .offset(y: -4)
                        .fixedSize()
                    }
                    .position(
                        x: geo.size.width / 2 + creatureOffset(for: creature, in: geo.size.width),
                        y: grassLineY - creatureSize / 2 - 4
                    )
                    .shadow(
                        color: creature.isLocal ? .white.opacity(0.15) : .clear,
                        radius: creature.isLocal ? 3 : 0
                    )
                    .contextMenu {
                        if creature.isLocal {
                            ForEach(PeerReaction.allCases) { reaction in
                                Button("\(reaction.emoji)  \(reaction.rawValue.capitalized)") {
                                    RoomManager.shared.sendReaction(reaction)
                                }
                            }
                        }
                    }
                }
            }
        }
        // Event log overlay (bottom section)
        .overlay(alignment: .bottom) {
            if AnimationSettings.shared.showEventLog && isExpanded {
                EventLogOverlay()
                    .padding(.horizontal, 20)
                    .padding(.bottom, AnimationSettings.shared.showStatusBar ? 22 : 8)
                    .transition(.opacity.combined(with: .offset(y: 10)))
            }
        }
        // Status bar overlay (very bottom)
        .overlay(alignment: .bottom) {
            if AnimationSettings.shared.showStatusBar && isExpanded {
                StatusBarOverlay()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 5)
                    .transition(.opacity)
            }
        }
        // Clip everything to the panel shape
        .clipShape(PanelClipShape(isExpanded: isExpanded, notchHalf: notchHalfForClip, panelHalf: panelHalfForClip, notchHeight: notchHeightForClip, cr: isExpanded ? 18 : 6))
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

    private func formatDuration(_ interval: TimeInterval) -> String {
        let m = Int(interval) / 60
        let s = Int(interval) % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    private func creatureOffset(for creature: CreatureDisplay, in width: CGFloat) -> CGFloat {
        let usable = width - creatureSize - 20
        return -usable / 2 + creature.xPosition * usable
    }

    // Pre-computed values for the clip shape
    private var notchHeightForClip: CGFloat {
        NSScreen.screens.first(where: { $0.hasNotch })?.safeAreaInsets.top ?? 32
    }
    private var notchHalfForClip: CGFloat {
        guard let screen = NSScreen.screens.first(where: { $0.hasNotch }),
              let notch = screen.notchSize,
              let win = screen.notchWindowFrame else { return 0 }
        return (notch.width * win.width / win.width) / 2
    }
    private var panelHalfForClip: CGFloat {
        guard let screen = NSScreen.screens.first(where: { $0.hasNotch }),
              let notch = screen.notchSize,
              let win = screen.notchWindowFrame else { return 100 }
        let notchHalf = (notch.width * win.width / win.width) / 2
        return min(win.width / 2 - 2, notchHalf + 50)
    }

    private func notchWidthInWindow(totalWidth: CGFloat) -> CGFloat {
        guard let screen = NSScreen.screens.first(where: { $0.hasNotch }),
              let notch = screen.notchSize,
              let win = screen.notchWindowFrame else { return totalWidth * 0.7 }
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
            // Collapsed: just a rect covering the notch bump area
            path.addRect(rect)
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Event Log Overlay

struct EventLogOverlay: View {
    @State private var feed = ActivityFeed.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(feed.items.prefix(4)) { item in
                HStack(spacing: 4) {
                    Text(item.icon)
                        .font(.system(size: 6))
                    Text(item.text)
                        .font(.system(size: 6, design: .monospaced))
                        .lineLimit(1)
                    Spacer()
                    Text(item.timeAgo)
                        .font(.system(size: 5))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .foregroundStyle(.white.opacity(0.55))
            }
        }
    }
}

// MARK: - Status Bar Overlay

struct StatusBarOverlay: View {
    @State private var stateMachine = StateMachine.shared
    @State private var stats = SessionStats.shared

    var body: some View {
        HStack(spacing: 6) {
            // Current task indicator
            let task = stateMachine.sessionStore.effectiveSession?.state.task ?? .idle
            let emotion = stateMachine.sessionStore.effectiveSession?.state.emotion ?? .neutral

            HStack(spacing: 3) {
                Circle()
                    .fill(taskColor(task))
                    .frame(width: 4, height: 4)
                Text(task.displayLabel)
                    .font(.system(size: 6, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }

            // Emotion
            if emotion != .neutral {
                Text(emotionLabel(emotion))
                    .font(.system(size: 5, weight: .medium))
                    .foregroundStyle(emotionColor(emotion).opacity(0.7))
            }

            Spacer()

            // Session time today
            Text("Today: \(SessionStats.format(stats.todayTotal))")
                .font(.system(size: 5, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    private func taskColor(_ task: CreatureTask) -> Color {
        switch task {
        case .idle:       return .gray
        case .working:    return .cyan
        case .thinking:   return .yellow
        case .sleeping:   return .purple
        case .compacting: return .red
        }
    }

    private func emotionLabel(_ emotion: CreatureEmotion) -> String {
        switch emotion {
        case .happy:      return "happy"
        case .sad:        return "sad"
        case .frustrated: return "frustrated"
        case .excited:    return "excited!"
        case .confused:   return "confused"
        case .tired:      return "tired"
        case .neutral:    return ""
        }
    }

    private func emotionColor(_ emotion: CreatureEmotion) -> Color {
        switch emotion {
        case .happy, .excited: return .green
        case .sad:             return .blue
        case .frustrated:      return .red
        case .confused:        return .yellow
        case .tired:           return .purple
        case .neutral:         return .gray
        }
    }
}

// MARK: - Pixel Reaction View

struct PixelReactionView: View {
    let reaction: PeerReaction

    var body: some View {
        Canvas { ctx, size in
            let grid = reaction.pixels
            let rows = grid.count
            let cols = grid.first?.count ?? 5
            let px = min(size.width / CGFloat(cols), size.height / CGFloat(rows))

            for (r, row) in grid.enumerated() {
                for (c, cell) in row.enumerated() {
                    guard cell != 0 else { continue }
                    let rect = CGRect(
                        x: CGFloat(c) * px, y: CGFloat(r) * px,
                        width: px + 0.5, height: px + 0.5
                    )
                    let color = cell == 1 ? reaction.primaryColor : reaction.secondaryColor
                    ctx.fill(Path(rect), with: .color(color))
                }
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
