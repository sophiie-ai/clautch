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
        if !isExpanded { return 9 } // smaller when collapsed
        switch creatures.count {
        case 0...3: return 15
        case 4:     return 13
        case 5:     return 11
        default:    return 9
        }
    }

    private let grassGreen = Color(red: 0.2, green: 0.5, blue: 0.25)
    private let grassDark = Color(red: 0.12, green: 0.35, blue: 0.15)

    /// Sky colors and star count based on time of day.
    private var skyTheme: (top: Color, bottom: Color, stars: Int) {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<8:   // Dawn
            return (Color(red: 0.45, green: 0.30, blue: 0.40),
                    Color(red: 0.75, green: 0.45, blue: 0.30), 3)
        case 8..<17:  // Day
            return (Color(red: 0.20, green: 0.45, blue: 0.75),
                    Color(red: 0.40, green: 0.65, blue: 0.85), 0)
        case 17..<19: // Dusk
            return (Color(red: 0.35, green: 0.20, blue: 0.45),
                    Color(red: 0.70, green: 0.35, blue: 0.30), 4)
        default:      // Night
            return (Color(red: 0.08, green: 0.10, blue: 0.25),
                    Color(red: 0.12, green: 0.18, blue: 0.35), 14)
        }
    }

    var body: some View {
        let screen = NSScreen.screens.first(where: { $0.hasNotch })
        let notchHeight = screen?.safeAreaInsets.top ?? 32
        let showLog = AnimationSettings.shared.showEventLog && isExpanded
        let showStatus = AnimationSettings.shared.showStatusBar && isExpanded

        Canvas { ctx, size in
            let notchWidth = notchWidthInWindow(totalWidth: size.width)
            let fullDrop = size.height - notchHeight
            let showLog = AnimationSettings.shared.showEventLog
            let showStatus = AnimationSettings.shared.showStatusBar
            // Layout constants — ground is always the same height
            let groundH: CGFloat = 7
            let logSpace: CGFloat = showLog ? 56 : 0
            let statusSpace: CGFloat = showStatus ? 8 : 0
            let scenePad: CGFloat = 2
            let minSky: CGFloat = 38
            let neededDrop = minSky + groundH + logSpace + statusSpace + scenePad
            let maxDrop = min(fullDrop, neededDrop)
            let hideWhenCollapsed = AnimationSettings.shared.hideWhenCollapsed
            let peekDrop: CGFloat = hideWhenCollapsed ? 0 : 16
            let dropHeight = isExpanded ? maxDrop : peekDrop
            let midX = size.width / 2
            let notchHalf = notchWidth / 2
            let expandedPanelHalf = min(size.width / 2 - 2, notchHalf + 50)
            let panelHalf = isExpanded ? expandedPanelHalf : notchHalf + 20
            let bottom = notchHeight + dropHeight
            let r: CGFloat = isExpanded ? 8 : 6
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
                // grassY calculated bottom-up so ground height is always constant
                let grassY = bottom - groundH - logSpace - statusSpace - scenePad

                // Sky gradient (fills from top of screen)
                let sky = skyTheme
                ctx.clip(to: path)
                let skyGradient = Gradient(colors: [sky.top, sky.bottom])
                ctx.fill(
                    Path(CGRect(x: midX - panelHalf, y: 0, width: panelHalf * 2, height: grassY)),
                    with: .linearGradient(skyGradient, startPoint: CGPoint(x: midX, y: 0), endPoint: CGPoint(x: midX, y: grassY))
                )

                // Stars (tiny dots in sky) — count varies by time of day
                let skyTop_y = notchHeight + 5
                let skyBottom_y = grassY - 5
                let starCount = showLog ? sky.stars + 6 : sky.stars
                if skyBottom_y > skyTop_y + 2 && starCount > 0 {
                    var starRng = StableRNG(seed: 77)
                    for _ in 0..<starCount {
                        let sx = midX - panelHalf + CGFloat.random(in: 0...(panelHalf * 2), using: &starRng)
                        let sy = CGFloat.random(in: skyTop_y...skyBottom_y, using: &starRng)
                        let alpha = Double.random(in: 0.3...0.7, using: &starRng)
                        ctx.fill(Path(CGRect(x: sx, y: sy, width: 1, height: 1)), with: .color(.white.opacity(alpha)))
                    }
                }

                // Ground — fixed height
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

                // Dark section below ground for event log + status bar
                if showLog || showStatus {
                    let darkY = grassY + groundH
                    ctx.fill(
                        Path(CGRect(x: midX - panelHalf, y: darkY, width: panelHalf * 2, height: bottom - darkY)),
                        with: .color(Color.black.opacity(0.85))
                    )
                    if showLog {
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
                let fullDrop = geo.size.height - notchHeight
                let showLog = AnimationSettings.shared.showEventLog
                let showStatus = AnimationSettings.shared.showStatusBar
                let groundH: CGFloat = 7
                let logSpace: CGFloat = showLog ? 56 : 0
                let statusSpace: CGFloat = showStatus ? 8 : 0
                let scenePad: CGFloat = 2
                let minSky: CGFloat = 38
                let neededDrop = minSky + groundH + logSpace + statusSpace + scenePad
                let maxDrop = min(fullDrop, neededDrop)
                let hideWhenCollapsed = AnimationSettings.shared.hideWhenCollapsed
                let peekDrop: CGFloat = hideWhenCollapsed ? 0 : 8
                let dropHeight = isExpanded ? maxDrop : peekDrop
                let bottom = notchHeight + dropHeight
                let grassLineY = isExpanded
                    ? bottom - groundH - logSpace - statusSpace - scenePad
                    : notchHeight + dropHeight

                ForEach(creatures) { creature in
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
                    .offset(y: bounceOffset)
                    .overlay(alignment: .top) {
                        VStack(spacing: 2) {
                            if isExpanded, let chat = creature.chatMessage {
                                PixelChatBubble(text: String(chat.prefix(50)))
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.5).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                                    .id("chat-\(creature.id)-\(chat)")
                            }

                            if isExpanded, let reaction = creature.reaction,
                               creature.reactionActive {
                                ReactionFloater(reaction: reaction)
                                    .id("reaction-\(creature.id)-\(reaction.rawValue)-\(creature.reactionActive)")
                            }

                            if isExpanded && creature.isLocal {
                                Text(creature.state.task.displayLabel)
                                    .font(.system(size: 7, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .transition(.opacity)
                            }
                        }
                        .offset(y: -18)
                        .fixedSize()
                    }
                    .position(
                        x: geo.size.width / 2 + creatureOffset(for: creature, in: geo.size.width),
                        y: grassLineY - creatureSize / 2 - 4
                    )
                    .animation(.easeInOut(duration: 2.0), value: creature.xPosition)
                    .shadow(
                        color: creature.isLocal ? .white.opacity(0.15) : .clear,
                        radius: creature.isLocal ? 3 : 0
                    )
                    .help(creatureTooltip(creature))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(creatureAccessibilityLabel(creature))
                    .accessibilityHint(creature.isLocal ? "Right-click to send a reaction" : "")
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
        // Event log + status bar overlays (positioned within visible panel)
        .overlay {
            if (AnimationSettings.shared.showEventLog || AnimationSettings.shared.showStatusBar) && isExpanded {
                GeometryReader { geo in
                    let nh = NSScreen.screens.first(where: { $0.hasNotch })?.safeAreaInsets.top ?? 32
                    let showLog = AnimationSettings.shared.showEventLog
                    let showStatus = AnimationSettings.shared.showStatusBar
                    let groundH: CGFloat = 7
                    let logH: CGFloat = 56
                    let logSpace: CGFloat = showLog ? logH : 0
                    let statusSpace: CGFloat = showStatus ? 8 : 0
                    let scenePad: CGFloat = 2
                    let minSky: CGFloat = 38
                    let fullDrop = geo.size.height - nh
                    let neededDrop = minSky + groundH + logSpace + statusSpace + scenePad
                    let maxDrop = min(fullDrop, neededDrop)
                    let bottom = nh + maxDrop
                    let grassY = bottom - groundH - logSpace - statusSpace - scenePad
                    let logTop = grassY + groundH

                    let contentWidth = geo.size.width - 72 // 36px padding each side

                    if showLog {
                        EventLogOverlay()
                            .frame(width: contentWidth, height: logH, alignment: .top)
                            .padding(.top, 2)
                            .position(x: geo.size.width / 2, y: logTop + logH / 2)
                            .transition(.opacity.combined(with: .offset(y: 10)))
                    }

                    if showStatus {
                        StatusBarOverlay()
                            .frame(width: contentWidth)
                            .position(x: geo.size.width / 2, y: bottom - scenePad - statusSpace / 2)
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

    private func formatDuration(_ interval: TimeInterval) -> String {
        let m = Int(interval) / 60
        let s = Int(interval) % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    private func creatureAccessibilityLabel(_ creature: CreatureDisplay) -> String {
        var parts = ["\(creature.displayName), \(creature.creatureType.displayName)"]
        parts.append(creature.state.task.displayLabel)
        if creature.state.emotion != .neutral {
            parts.append(creature.state.emotion.rawValue)
        }
        if let chat = creature.chatMessage {
            parts.append("says: \(chat)")
        }
        if let reaction = creature.reaction, creature.reactionActive {
            parts.append("reacted with \(reaction.rawValue)")
        }
        return parts.joined(separator: ", ")
    }

    private func creatureTooltip(_ creature: CreatureDisplay) -> String {
        var parts = [creature.displayName, creature.state.task.displayLabel]
        if let duration = creature.sessionDuration {
            parts.append(formatDuration(duration))
        }
        return parts.joined(separator: " · ")
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
                    Text(item.text)
                        .font(.system(size: 7, design: .monospaced))
                        .lineLimit(1)
                    Spacer()
                    Text(item.timeAgo)
                        .font(.system(size: 6))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .foregroundStyle(.white.opacity(0.55))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(item.text), \(item.timeAgo) ago")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Activity log")
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

            // Usage: today + week with reset info
            Text("\(SessionStats.format(stats.todayTotal))")
                .font(.system(size: 7, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))

            Text("·")
                .font(.system(size: 7))
                .foregroundStyle(.white.opacity(0.2))

            Text("Wk: \(SessionStats.format(stats.weekTotal))")
                .font(.system(size: 7, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))

            Text("·")
                .font(.system(size: 7))
                .foregroundStyle(.white.opacity(0.2))

            Text("Resets \(SessionStats.weekResetLabel)")
                .font(.system(size: 7, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.3))
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

// MARK: - Pixel Chat Bubble

/// A pixel-art speech bubble with a small triangular tail.
struct PixelChatBubble: View {
    let text: String

    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.system(size: 7, weight: .medium, design: .rounded))
                .foregroundStyle(.black)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    PixelBubbleShape()
                        .fill(.white.opacity(0.92))
                )
                .background(
                    PixelBubbleShape()
                        .stroke(Color.black.opacity(0.15), lineWidth: 0.5)
                )

            // Pixel tail (3 rows of decreasing width)
            VStack(spacing: 0) {
                Rectangle().fill(.white.opacity(0.92)).frame(width: 5, height: 1)
                Rectangle().fill(.white.opacity(0.92)).frame(width: 3, height: 1)
                Rectangle().fill(.white.opacity(0.92)).frame(width: 1, height: 1)
            }
        }
    }
}

/// Stepped rectangle shape for pixel aesthetic.
private struct PixelBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s: CGFloat = 1.5  // pixel step size
        var p = Path()
        // Rounded-ish rectangle with stepped corners
        p.move(to: CGPoint(x: rect.minX + s, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - s, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + s))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - s))
        p.addLine(to: CGPoint(x: rect.maxX - s, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + s, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - s))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + s))
        p.closeSubpath()
        return p
    }
}

// MARK: - Reaction Floater

/// Animates a reaction floating upward and fading out.
struct ReactionFloater: View {
    let reaction: PeerReaction
    @State private var floatOffset: CGFloat = 0
    @State private var opacity: Double = 1.0

    var body: some View {
        PixelReactionView(reaction: reaction)
            .frame(width: 15, height: 15)
            .offset(y: floatOffset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 2.5)) {
                    floatOffset = -14
                }
                withAnimation(.easeIn(duration: 2.5).delay(0.5)) {
                    opacity = 0
                }
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
