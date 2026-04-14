import SwiftUI

/// Shared hover state, set by the AppKit tracking area.
@Observable
final class NotchHoverState {
    static let shared = NotchHoverState()

    private static let persistenceKey = "com.clautch.panelExpanded"

    var isHovered: Bool = false {
        didSet {
            UserDefaults.standard.set(isHovered, forKey: Self.persistenceKey)
        }
    }

    /// The screen the notch panel is currently placed on, set by AppDelegate.
    var activeScreen: NSScreen?

    init() {
        self.isHovered = UserDefaults.standard.bool(forKey: Self.persistenceKey)
    }
}

/// Root view rendered inside the notch panel.
/// Minimal by default — shows creature peeking out and grass.
/// Expands into a Dynamic Island panel on hover.
struct NotchContentView: View {
    @State private var stateMachine = StateMachine.shared
    @State private var roomManager = RoomManager.shared
    @State private var hoverState = NotchHoverState.shared
    @State private var wanderPosition: CGFloat = 0.25
    @State private var wanderTimer: Timer?
    @State private var isWalking: Bool = false
    @State private var walkingRight: Bool = true

    private var isExpanded: Bool { hoverState.isHovered }

    var body: some View {
        GrassIslandView(creatures: allCreatures, isExpanded: isExpanded, isWalking: isWalking)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .onAppear { if isExpanded { startWandering() } }
            .onDisappear { stopWandering() }
            .onChange(of: isExpanded) { _, expanded in
                if expanded {
                    startWandering()
                } else {
                    stopWandering()
                }
            }
    }

    // MARK: - Wander

    private func startWandering() {
        guard wanderTimer == nil else { return }
        wanderTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            // Don't wander when status is active AND Claude Code is idle
            // (if Claude is thinking/working, it overrides the status so wandering is fine)
            let effectiveTask = stateMachine.sessionStore.effectiveSession?.state.task ?? .idle
            let claudeActive = effectiveTask == .thinking || effectiveTask == .working
            if let status = stateMachine.activeStatus, !status.isExpired, !claudeActive {
                isWalking = false
                return
            }
            let newTarget = CGFloat.random(in: 0.05...0.95)
            walkingRight = newTarget > wanderPosition
            isWalking = true
            withAnimation(.spring(response: 1.8, dampingFraction: 0.85)) {
                wanderPosition = newTarget
            }
            roomManager.updatePosition(newTarget)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isWalking = false
            }
        }
    }

    private func stopWandering() {
        wanderTimer?.invalidate()
        wanderTimer = nil
        isWalking = false
    }

    /// Build unified creature list from local sessions + remote peers.
    private var allCreatures: [CreatureDisplay] {
        let profile = UserProfile.current
        var creatures: [CreatureDisplay] = []

        // One creature per user — use the most active session's state,
        // or idle if no sessions are running. Status overrides creature behaviour.
        let effective = stateMachine.sessionStore.effectiveSession
        var localCreatureState = effective?.state ?? CreatureState()
        // Status only overrides when Claude Code is idle — active thinking/working takes priority
        let claudeActive = localCreatureState.task == .thinking || localCreatureState.task == .working
        let statusActive = stateMachine.activeStatus != nil && !stateMachine.activeStatus!.isExpired
        if statusActive && !claudeActive, let preset = stateMachine.activeStatus?.preset {
            localCreatureState.task = preset.creatureTask
            localCreatureState.emotion = preset.creatureEmotion
        }
        let localReaction = roomManager.localState?.reaction
        let localReactionActive = roomManager.localState?.hasActiveReaction ?? false
        let localInteractionActive = roomManager.localState?.hasActiveInteraction ?? false
        creatures.append(CreatureDisplay(
            id: "local",
            state: localCreatureState,
            creatureType: profile?.creatureType ?? .ghost,
            colorPreset: profile?.colorPreset ?? .none,
            accessory: profile?.accessory ?? .none,
            evolution: GamificationStore.shared.evolution,
            xPosition: wanderPosition,
            isLocal: true,
            displayName: profile?.displayName ?? "You",
            sessionDuration: effective.map { Date().timeIntervalSince($0.startedAt) },
            lastToolName: effective?.lastToolName,
            reaction: localReactionActive ? localReaction : nil,
            reactionActive: localReactionActive,
            chatMessage: roomManager.localState?.activeChatMessage,
            interaction: localInteractionActive ? roomManager.localState?.interaction : nil,
            interactionTarget: localInteractionActive ? roomManager.localState?.interactionTarget : nil,
            interactionActive: localInteractionActive,
            statusPreset: stateMachine.activeStatus.flatMap { $0.isExpired ? nil : $0.preset },
            statusText: stateMachine.activeStatus.flatMap { $0.isExpired ? nil : ($0.customText ?? $0.preset?.displayName) },
            hasStatus: stateMachine.activeStatus != nil && !stateMachine.activeStatus!.isExpired,
            personality: PersonalityEngine.shared.personality
        ))

        if let myId = profile?.peerId {
            let remotePeers = roomManager.peerStore.visiblePeers(excludingPeerId: myId)
            for peer in remotePeers {
                let peerX = peer.xPosition ?? roomManager.peerStore.xPosition(for: peer.peerId)
                creatures.append(CreatureDisplay(
                    id: "remote-\(peer.peerId)",
                    state: CreatureState(
                        task: peer.task,
                        emotion: peer.emotion,
                        lastActivity: peer.timestamp
                    ),
                    creatureType: peer.creatureType,
                    colorPreset: peer.colorPreset,
                    accessory: peer.accessory,
                    evolution: peer.evolution,
                    xPosition: peerX,
                    isLocal: false,
                    displayName: peer.displayName,
                    reaction: peer.hasActiveReaction ? peer.reaction : nil,
                    reactionActive: peer.hasActiveReaction,
                    chatMessage: peer.activeChatMessage,
                    isTyping: peer.isTyping ?? false,
                    interaction: peer.hasActiveInteraction ? peer.interaction : nil,
                    interactionTarget: peer.hasActiveInteraction ? peer.interactionTarget : nil,
                    interactionActive: peer.hasActiveInteraction,
                    statusPreset: peer.activeStatusPreset,
                    statusText: peer.activeStatusDisplay,
                    hasStatus: peer.hasActiveStatus
                ))
            }
        }

        // Push creatures to the interaction engine — only caches the list
        // (@ObservationIgnored), so it can't trigger SwiftUI re-evaluation.
        // The engine's 1-second tick timer drives the actual interaction logic.
        CreatureInteractionEngine.shared.setCreatures(creatures)

        // Compute facing: each creature faces its nearest neighbor
        return computeFacing(creatures)
    }

    /// Compute facing directions and return sorted by xPosition (avoids re-sorting in ForEach).
    private func computeFacing(_ creatures: [CreatureDisplay]) -> [CreatureDisplay] {
        guard creatures.count > 1 else { return creatures }
        let sorted = creatures.sorted { $0.xPosition < $1.xPosition }
        let engine = CreatureInteractionEngine.shared
        return sorted.map { c in
            var c = c
            // Interaction engine can override facing for paired animations
            if let override = engine.facingOverride(for: c.id) {
                c.facingRight = override
            } else if c.isLocal && isWalking {
                // When walking, local creature faces travel direction
                c.facingRight = walkingRight
            } else if let nearest = sorted.filter({ $0.id != c.id })
                .min(by: { abs($0.xPosition - c.xPosition) < abs($1.xPosition - c.xPosition) }) {
                c.facingRight = nearest.xPosition > c.xPosition
            }
            return c
        }
    }
}
