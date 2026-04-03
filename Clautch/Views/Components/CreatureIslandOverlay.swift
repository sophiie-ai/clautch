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

    var body: some View {
        ForEach(creatures) { creature in
            HoverBounceView {
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
            // Attention indicators
            .overlay(alignment: .topTrailing) {
                if creature.isLocal && creature.state.needsPermission {
                    NeedsPermissionBadge()
                        .offset(x: 4, y: -2)
                        .transition(.scale.combined(with: .opacity))
                } else if creature.isLocal && creature.state.needsInput {
                    NeedsInputDot()
                        .offset(x: 4, y: -2)
                        .transition(.scale.combined(with: .opacity))
                }
            }
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
            .accessibilityElement(children: .combine)
            .accessibilityLabel(creatureAccessibilityLabel(creature))
            .accessibilityHint(creature.isLocal ? "Right-click to send a reaction" : "Click to wave")
            .onTapGesture {
                if !creature.isLocal && isExpanded {
                    RoomManager.shared.sendReaction(.wave)
                }
            }
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

    private func creatureTooltip(_ creature: CreatureDisplay) -> String {
        var parts = [creature.displayName, creature.state.task.displayLabel]
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

// MARK: - Needs Permission Badge

struct NeedsPermissionBadge: View {
    @State private var pulse = false

    var body: some View {
        Image(systemName: "shield.fill")
            .font(.system(size: 7))
            .foregroundStyle(.yellow)
            .shadow(color: .yellow.opacity(0.5), radius: pulse ? 3 : 1)
            .scaleEffect(pulse ? 1.2 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

// MARK: - Needs Input Dot

struct NeedsInputDot: View {
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(Color.orange)
            .frame(width: 5, height: 5)
            .shadow(color: .orange.opacity(0.6), radius: pulse ? 3 : 1)
            .scaleEffect(pulse ? 1.3 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulse = true
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
