import SwiftUI

// MARK: - Creature Island Overlay

/// Renders all creatures with their overlays (chat, reactions, typing, attention indicators).
struct CreatureIslandOverlay: View {
    let creatures: [CreatureDisplay]
    let isExpanded: Bool
    let isWalking: Bool
    let creatureSize: CGFloat
    let bounceScale: CGFloat
    let bounceOffset: CGFloat
    let grassLineY: CGFloat
    let viewWidth: CGFloat
    let notchWidthFn: (CGFloat) -> CGFloat

    @State private var gamification = GamificationStore.shared
    @State private var currentCelebration: AchievementId?
    @State private var petHearts: [PetHeart] = []
    @State private var pokeIndicators: [PokeIndicator] = []
    @State private var foodParticles: [FoodParticle] = []
    @State private var pokeJumping: Bool = false

    struct PetHeart: Identifiable {
        let id = UUID()
        let xOffset: CGFloat
        let createdAt: Date
    }

    struct PokeIndicator: Identifiable {
        let id = UUID()
        let xOffset: CGFloat
        let symbol: String
    }

    struct FoodParticle: Identifiable {
        let id = UUID()
        let xOffset: CGFloat
        let yStart: CGFloat
    }

    var body: some View {
        ForEach(creatures) { creature in
            HoverBounceView {
                CreatureSpriteView(
                    state: creature.state,
                    creatureType: creature.creatureType,
                    colorPreset: creature.colorPreset,
                    accessory: creature.accessory,
                    evolution: creature.evolution,
                    isExpanded: isExpanded,
                    isWalking: isWalking && creature.isLocal,
                    needsInput: creature.isLocal && creature.state.needsInput,
                    needsPermission: creature.isLocal && creature.state.needsPermission,
                    personality: creature.personality
                )
                .frame(width: creatureSize, height: creatureSize)
                .scaleEffect(x: creature.facingRight ? 1 : -1, y: 1)
                .animation(.easeInOut(duration: 0.3), value: creature.state.task)
            }
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

                    if isExpanded && creature.isTyping && creature.chatMessage == nil {
                        TypingIndicator()
                            .transition(.opacity)
                    }

                    if isExpanded, let reaction = creature.reaction,
                       creature.reactionActive {
                        ReactionFloater(reaction: reaction)
                            .id("reaction-\(creature.id)-\(reaction.rawValue)-\(creature.reactionActive)")
                    }

                    if isExpanded {
                        let claudeActive = creature.state.task == .thinking || creature.state.task == .working
                        let label: String = {
                            if creature.hasStatus && !claudeActive {
                                return creature.statusText ?? creature.statusPreset?.displayName ?? creature.state.task.displayLabel
                            }
                            return creature.state.task.displayLabel
                        }()
                        Text(label)
                            .font(.system(size: 7, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                            .transition(.opacity)
                    }

                    if isExpanded, creature.isLocal, let celebration = currentCelebration {
                        AchievementFloater(achievementId: celebration) {
                            currentCelebration = gamification.popCelebration()
                        }
                        .id("achievement-\(celebration.rawValue)")
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .offset(y: -18)
                .fixedSize()
            }
            // Attention indicators are now rendered as pixel art inside CreatureSpriteView
            .overlay {
                if creature.isLocal {
                    ForEach(petHearts) { heart in
                        HeartFloater(heart: heart)
                    }
                    ForEach(pokeIndicators) { poke in
                        PokeFloater(indicator: poke)
                    }
                    ForEach(foodParticles) { food in
                        FoodFloater(particle: food)
                    }
                }
            }
            .offset(y: (pokeJumping && creature.isLocal) ? -8 : 0)
            .position(
                x: viewWidth / 2 + creatureOffset(for: creature),
                y: grassLineY - creatureSize / 2 - 4
            )
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isExpanded)
            .animation(.spring(response: 1.8, dampingFraction: 0.85), value: creature.xPosition)
            .shadow(
                color: creature.isLocal ? .white.opacity(0.15) : .clear,
                radius: creature.isLocal ? 3 : 0
            )
            .help(creatureTooltip(creature))
            .onChange(of: gamification.celebrationQueue.count) {
                if currentCelebration == nil, creature.isLocal {
                    currentCelebration = gamification.popCelebration()
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(creatureAccessibilityLabel(creature))
            .accessibilityHint(creature.isLocal ? "Right-click to send a reaction" : "Click to wave")
            .gesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        if creature.isLocal && isExpanded {
                            feedCreature()
                        }
                    }
            )
            .onTapGesture(count: 2) {
                if creature.isLocal && isExpanded {
                    pokeCreature()
                }
            }
            .onTapGesture {
                if !creature.isLocal && isExpanded {
                    RoomManager.shared.sendReaction(.wave)
                } else if creature.isLocal && isExpanded {
                    petCreature()
                }
            }
            .contextMenu {
                if creature.isLocal {
                    Section("Reactions") {
                        ForEach(PeerReaction.allCases) { reaction in
                            Button("\(reaction.emoji)  \(reaction.rawValue.capitalized)") {
                                RoomManager.shared.sendReaction(reaction)
                            }
                        }
                    }
                } else {
                    Section("Interact") {
                        ForEach(PeerInteraction.allCases) { interaction in
                            Button("\(interaction.emoji)  \(interaction.displayName)") {
                                let targetId = creature.id.replacingOccurrences(of: "remote-", with: "")
                                RoomManager.shared.sendInteraction(interaction, to: targetId)
                            }
                        }
                    }
                    Section("Reactions") {
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

    private func creatureOffset(for creature: CreatureDisplay) -> CGFloat {
        if !isExpanded {
            let notchW = notchWidthFn(viewWidth)
            let notchHalf = notchW / 2
            let sideMargin: CGFloat = 8
            let idx = creatures.firstIndex(where: { $0.id == creature.id }) ?? 0
            let side: CGFloat = idx % 2 == 0 ? -1 : 1
            let slot = CGFloat(idx / 2)
            return side * (notchHalf + sideMargin + creatureSize * slot + creatureSize / 2)
        }
        let usable = viewWidth - creatureSize - 20
        return -usable / 2 + creature.xPosition * usable
    }

    private func petCreature() {
        let heart = PetHeart(
            xOffset: CGFloat.random(in: -10...10),
            createdAt: Date()
        )
        withAnimation { petHearts.append(heart) }
        NSSound(named: "Pop")?.play()
        StateMachine.shared.applyLocalInteraction(.pet)
        // Remove after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation { petHearts.removeAll { $0.id == heart.id } }
        }
    }

    private func pokeCreature() {
        let indicator = PokeIndicator(
            xOffset: CGFloat.random(in: -6...6),
            symbol: "!"
        )
        withAnimation { pokeIndicators.append(indicator) }
        withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) {
            pokeJumping = true
        }
        NSSound(named: "Tink")?.play()
        StateMachine.shared.applyLocalInteraction(.poke)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation { pokeJumping = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation { pokeIndicators.removeAll { $0.id == indicator.id } }
        }
    }

    private func feedCreature() {
        // Cap at 3 feeds per day
        guard gamification.dailyCounters.feedCount < 3 else { return }
        for i in 0..<3 {
            let particle = FoodParticle(
                xOffset: CGFloat.random(in: -8...8),
                yStart: CGFloat(i) * -4
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                withAnimation { foodParticles.append(particle) }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2 + Double(i) * 0.15) {
                withAnimation { foodParticles.removeAll { $0.id == particle.id } }
            }
        }
        NSSound(named: "Pop")?.play()
        StateMachine.shared.applyLocalInteraction(.feed)
    }

    private func creatureTooltip(_ creature: CreatureDisplay) -> String {
        var parts = [creature.displayName]
        if creature.hasStatus {
            let statusText = creature.statusText ?? creature.statusPreset?.displayName ?? ""
            if !statusText.isEmpty {
                parts.append(statusText)
            }
        } else {
            parts.append(creature.state.task.displayLabel)
        }
        if let duration = creature.sessionDuration {
            let m = Int(duration) / 60
            let s = Int(duration) % 60
            parts.append(m > 0 ? "\(m)m \(s)s" : "\(s)s")
        }
        return parts.joined(separator: " · ")
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
}

// MARK: - Proximity Effects

/// Renders passive effects (hearts, sparkles) between nearby creatures,
/// plus autonomous creature-to-creature interactions when triggered.
struct ProximityEffectsView: View {
    let creatures: [CreatureDisplay]
    let isExpanded: Bool
    let creatureSize: CGFloat
    let grassLineY: CGFloat
    let viewWidth: CGFloat

    private let proximityThreshold: CGFloat = 0.15  // xPosition distance

    var body: some View {
        if isExpanded && creatures.count >= 2 {
            TimelineView(.animation(minimumInterval: 0.1)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Canvas { ctx, size in
                    // Draw autonomous interaction effects
                    if let interaction = CreatureInteractionEngine.shared.activeInteraction,
                       interaction.isActive {
                        drawAutonomousInteraction(ctx: ctx, size: size, t: t, interaction: interaction)
                    }

                    let pairs = nearbyPairs()
                    for (a, b) in pairs {
                        let ax = size.width / 2 + xOffset(a)
                        let bx = size.width / 2 + xOffset(b)
                        let midX = (ax + bx) / 2
                        let y = grassLineY - creatureSize / 2 - 4

                        // Cycle through effects based on pair seed
                        let seed = abs(a.id.hashValue ^ b.id.hashValue)
                        let effectType = seed % 3
                        let cycle = 6.0
                        let phase = t.truncatingRemainder(dividingBy: cycle) / cycle

                        switch effectType {
                        case 0: // Floating hearts
                            for i in 0..<3 {
                                let offset = Double(i) / 3.0
                                let p = (phase + offset).truncatingRemainder(dividingBy: 1.0)
                                let hx = midX + CGFloat(sin(t * 1.5 + Double(i) * 2.0)) * 4
                                let hy = y - CGFloat(p) * 16 - 8
                                let alpha = 1.0 - p
                                ctx.fill(
                                    heartPath(at: CGPoint(x: hx, y: hy), size: 3),
                                    with: .color(Color.pink.opacity(alpha * 0.6))
                                )
                            }
                        case 1: // Sparkle trail
                            for i in 0..<4 {
                                let frac = CGFloat(i) / 4.0
                                let sx = ax + (bx - ax) * frac
                                let sy = y - 6 + CGFloat(sin(t * 3.0 + Double(i) * 1.5)) * 4
                                let pulse = 0.3 + 0.7 * abs(sin(t * 2.5 + Double(i)))
                                ctx.fill(
                                    Path(CGRect(x: sx - 0.5, y: sy - 0.5, width: 1, height: 1)),
                                    with: .color(Color.yellow.opacity(pulse * 0.5))
                                )
                            }
                        default: // Musical notes
                            for i in 0..<2 {
                                let offset = Double(i) * 0.5
                                let p = (phase + offset).truncatingRemainder(dividingBy: 1.0)
                                let nx = midX + CGFloat(sin(t * 0.8 + Double(i) * 3.0)) * 6
                                let ny = y - CGFloat(p) * 14 - 10
                                let alpha = 0.5 + 0.5 * (1.0 - p)
                                ctx.fill(
                                    Path(CGRect(x: nx, y: ny, width: 2, height: 2)),
                                    with: .color(Color.cyan.opacity(alpha * 0.5))
                                )
                                ctx.fill(
                                    Path(CGRect(x: nx + 2, y: ny - 1, width: 0.5, height: 3)),
                                    with: .color(Color.cyan.opacity(alpha * 0.4))
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    private func nearbyPairs() -> [(CreatureDisplay, CreatureDisplay)] {
        var pairs: [(CreatureDisplay, CreatureDisplay)] = []
        for i in 0..<creatures.count {
            for j in (i + 1)..<creatures.count {
                let dist = abs(creatures[i].xPosition - creatures[j].xPosition)
                if dist < proximityThreshold {
                    pairs.append((creatures[i], creatures[j]))
                }
            }
        }
        return pairs
    }

    private func xOffset(_ creature: CreatureDisplay) -> CGFloat {
        let usable = viewWidth - creatureSize - 20
        return -usable / 2 + creature.xPosition * usable
    }

    private func drawAutonomousInteraction(
        ctx: GraphicsContext, size: CGSize, t: Double,
        interaction: CreatureInteractionEngine.AutonomousInteraction
    ) {
        let creatureA = creatures.first { $0.id == interaction.creatureA }
        let creatureB = creatures.first { $0.id == interaction.creatureB }
        guard let a = creatureA, let b = creatureB else { return }

        let ax = size.width / 2 + xOffset(a)
        let bx = size.width / 2 + xOffset(b)
        let midX = (ax + bx) / 2
        let y = grassLineY - creatureSize / 2 - 4
        let progress = interaction.progress

        switch interaction.type {
        case .faceEachOther:
            // Subtle glow between creatures
            let glow = sin(progress * .pi) * 0.15
            ctx.fill(
                Path(ellipseIn: CGRect(x: midX - 6, y: y - 4, width: 12, height: 8)),
                with: .color(.white.opacity(glow))
            )

        case .bump:
            // Collision particles at midpoint
            let burst = progress < 0.3 ? progress / 0.3 : max(0, 1.0 - (progress - 0.3) / 0.7)
            for i in 0..<5 {
                let angle = Double(i) * .pi * 2 / 5 + t * 2
                let radius = burst * 8
                let px = midX + CGFloat(cos(angle)) * CGFloat(radius)
                let py = y - 4 + CGFloat(sin(angle)) * CGFloat(radius) * 0.5
                ctx.fill(
                    Path(CGRect(x: px - 0.5, y: py - 0.5, width: 1, height: 1)),
                    with: .color(.white.opacity(burst * 0.6))
                )
            }

        case .wave:
            // Small wave indicator near one creature
            let wavePhase = sin(progress * .pi * 3)
            let waveX = ax + (bx > ax ? 6 : -6)
            ctx.fill(
                Path(CGRect(x: waveX - 1, y: y - 6 + CGFloat(wavePhase) * 2, width: 2, height: 1.5)),
                with: .color(.yellow.opacity(sin(progress * .pi) * 0.5))
            )

        case .playTogether:
            // Shared sparkles bouncing between creatures
            let sparkleAlpha = sin(progress * .pi)
            for i in 0..<4 {
                let frac = CGFloat(i) / 3.0
                let sx = ax + (bx - ax) * frac
                let bounce = CGFloat(sin(t * 4 + Double(i) * 1.5)) * 5
                ctx.fill(
                    Path(CGRect(x: sx - 0.5, y: y - 8 + bounce, width: 1.5, height: 1.5)),
                    with: .color(.yellow.opacity(sparkleAlpha * 0.5))
                )
            }

        case .share:
            // Particle stream from A to B
            let streamAlpha = sin(progress * .pi) * 0.6
            for i in 0..<6 {
                let frac = (Double(i) / 6.0 + t * 0.5).truncatingRemainder(dividingBy: 1.0)
                let sx = ax + (bx - ax) * CGFloat(frac)
                let sy = y - 6 + CGFloat(sin(frac * .pi)) * -4
                ctx.fill(
                    Path(CGRect(x: sx - 0.5, y: sy - 0.5, width: 1, height: 1)),
                    with: .color(.cyan.opacity(streamAlpha * (1.0 - frac)))
                )
            }
        }
    }

    private func heartPath(at center: CGPoint, size: CGFloat) -> Path {
        // Simple pixel heart: 3x3
        var p = Path()
        let s = size / 3
        p.addRect(CGRect(x: center.x - s, y: center.y - s / 2, width: s, height: s))
        p.addRect(CGRect(x: center.x, y: center.y - s / 2, width: s, height: s))
        p.addRect(CGRect(x: center.x - s * 1.5, y: center.y, width: s, height: s))
        p.addRect(CGRect(x: center.x + s * 0.5, y: center.y, width: s, height: s))
        p.addRect(CGRect(x: center.x - s, y: center.y + s * 0.5, width: 2 * s, height: s))
        p.addRect(CGRect(x: center.x - s / 2, y: center.y + s * 1.5, width: s, height: s / 2))
        return p
    }
}

// MARK: - Heart Floater

struct HeartFloater: View {
    let heart: CreatureIslandOverlay.PetHeart
    @State private var animate = false

    var body: some View {
        Text("♥")
            .font(.system(size: 10))
            .foregroundStyle(.pink)
            .offset(x: heart.xOffset, y: animate ? -20 : 0)
            .opacity(animate ? 0 : 1)
            .scaleEffect(animate ? 1.3 : 0.5)
            .onAppear {
                withAnimation(.easeOut(duration: 0.9)) {
                    animate = true
                }
            }
    }
}

// MARK: - Poke Floater

struct PokeFloater: View {
    let indicator: CreatureIslandOverlay.PokeIndicator
    @State private var animate = false

    var body: some View {
        Text(indicator.symbol)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.orange)
            .offset(x: indicator.xOffset, y: animate ? -18 : -4)
            .opacity(animate ? 0 : 1)
            .scaleEffect(animate ? 1.2 : 0.6)
            .onAppear {
                withAnimation(.easeOut(duration: 0.7)) {
                    animate = true
                }
            }
    }
}

// MARK: - Food Floater

struct FoodFloater: View {
    let particle: CreatureIslandOverlay.FoodParticle
    @State private var animate = false

    var body: some View {
        Text(".")
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.brown)
            .offset(x: particle.xOffset, y: animate ? 6 : particle.yStart - 16)
            .opacity(animate ? 0 : 0.8)
            .scaleEffect(animate ? 0.3 : 0.8)
            .onAppear {
                withAnimation(.easeIn(duration: 0.9)) {
                    animate = true
                }
            }
    }
}

// MARK: - Hover Bounce

struct HoverBounceView<Content: View>: View {
    @ViewBuilder var content: Content
    @State private var isHovered = false
    @State private var hoverBounce: CGFloat = 0

    var body: some View {
        content
            .offset(y: hoverBounce)
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    withAnimation(.easeOut(duration: 0.12)) {
                        hoverBounce = -4
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                            hoverBounce = 0
                        }
                    }
                }
            }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var phase: Double = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 6)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(.white.opacity(0.7))
                        .frame(width: 3, height: 3)
                        .offset(y: -2 * sin(t * 4 + Double(i) * 0.8))
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(
                PixelBubbleShape()
                    .fill(.white.opacity(0.3))
            )
        }
    }
}

// MARK: - Collapsed Chat Overlay

/// Renders chat bubbles and emotion indicators for collapsed creatures, outside the panel clip shape.
struct CollapsedChatOverlay: View {
    let creatures: [CreatureDisplay]
    let creatureSize: CGFloat
    let grassLineY: CGFloat
    let viewWidth: CGFloat
    let notchWidthFn: (CGFloat) -> CGFloat

    var body: some View {
        ForEach(creatures) { creature in
            let cx = viewWidth / 2 + creatureOffset(for: creature)

            if creature.state.emotion != .neutral {
                CollapsedEmotionIndicator(emotion: creature.state.emotion)
                    .position(
                        x: cx + emotionSideOffset(for: creature),
                        y: grassLineY - creatureSize / 2 - 4
                    )
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: creature.state.emotion)
            }

            if let chat = creature.chatMessage {
                CollapsedChatBubble(text: String(chat.prefix(30)))
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.5).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .id("collapsed-chat-\(creature.id)-\(chat)")
                    .position(x: cx, y: grassLineY + 6)
                    .animation(.easeInOut(duration: 0.3), value: creature.chatMessage)
            }
        }
    }

    private func creatureOffset(for creature: CreatureDisplay) -> CGFloat {
        let notchW = notchWidthFn(viewWidth)
        let notchHalf = notchW / 2
        let sideMargin: CGFloat = 8
        let idx = creatures.firstIndex(where: { $0.id == creature.id }) ?? 0
        let side: CGFloat = idx % 2 == 0 ? -1 : 1
        let slot = CGFloat(idx / 2)
        return side * (notchHalf + sideMargin + creatureSize * slot + creatureSize / 2)
    }

    /// Place the emotion indicator on the outer side (away from notch).
    private func emotionSideOffset(for creature: CreatureDisplay) -> CGFloat {
        let idx = creatures.firstIndex(where: { $0.id == creature.id }) ?? 0
        let outward: CGFloat = idx % 2 == 0 ? -1 : 1
        return outward * (creatureSize / 2 + 4)
    }
}

// MARK: - Collapsed Chat Bubble

/// Compact chat bubble shown below collapsed creatures — smaller font, tighter padding.
struct CollapsedChatBubble: View {
    let text: String

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Rectangle().fill(.white.opacity(0.92)).frame(width: 1, height: 1)
                Rectangle().fill(.white.opacity(0.92)).frame(width: 3, height: 1)
            }

            Text(text)
                .font(.system(size: 6, weight: .medium, design: .rounded))
                .foregroundStyle(.black)
                .lineLimit(1)
                .padding(.horizontal, 3)
                .padding(.vertical, 1.5)
                .background(
                    PixelBubbleShape()
                        .fill(.white.opacity(0.92))
                )
                .background(
                    PixelBubbleShape()
                        .stroke(Color.black.opacity(0.15), lineWidth: 0.5)
                )
        }
    }
}

// MARK: - Pixel Chat Bubble

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

            VStack(spacing: 0) {
                Rectangle().fill(.white.opacity(0.92)).frame(width: 5, height: 1)
                Rectangle().fill(.white.opacity(0.92)).frame(width: 3, height: 1)
                Rectangle().fill(.white.opacity(0.92)).frame(width: 1, height: 1)
            }
        }
    }
}

struct PixelBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s: CGFloat = 1.5
        var p = Path()
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

// MARK: - Collapsed Emotion Indicator

/// Animated indicator shown to the side of a collapsed creature to convey its emotion.
struct CollapsedEmotionIndicator: View {
    let emotion: CreatureEmotion
    @State private var pulse: Double = 0.6

    private var symbol: String {
        switch emotion {
        case .neutral:    ""
        case .happy:      "✦"
        case .sad:        "◆"
        case .frustrated: "!"
        case .excited:    "★"
        case .confused:   "?"
        case .tired:      "z"
        }
    }

    private var color: Color {
        switch emotion {
        case .neutral:    .clear
        case .happy:      .yellow
        case .sad:        Color(red: 0.4, green: 0.6, blue: 1.0)
        case .frustrated: .red
        case .excited:    .orange
        case .confused:   Color(red: 0.8, green: 0.6, blue: 0.2)
        case .tired:      Color(red: 0.5, green: 0.6, blue: 0.8)
        }
    }

    // Pulse via Core Animation (layer opacity), not a TimelineView-driven
    // attributed-string mutation — the previous version re-measured the
    // Text on every timeline tick, pegging CoreText in the main thread.
    var body: some View {
        Text(symbol)
            .font(.system(size: 7, weight: .bold))
            .foregroundStyle(color)
            .opacity(pulse)
            .onAppear {
                pulse = 0.6
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulse = 1.0
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
