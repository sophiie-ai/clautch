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

    private var isExpanded: Bool { hoverState.isHovered }

    var body: some View {
        GrassIslandView(creatures: allCreatures, isExpanded: isExpanded, isWalking: isWalking)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .onAppear { startWandering() }
            .onDisappear { wanderTimer?.invalidate() }
    }

    // MARK: - Wander

    private func startWandering() {
        wanderTimer?.invalidate()
        wanderTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            let newTarget = CGFloat.random(in: 0.05...0.95)
            isWalking = true
            withAnimation(.easeInOut(duration: 2.5)) {
                wanderPosition = newTarget
            }
            // Stop walking after the animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                isWalking = false
            }
        }
    }

    /// Build unified creature list from local sessions + remote peers.
    private var allCreatures: [CreatureDisplay] {
        let profile = UserProfile.current
        var creatures: [CreatureDisplay] = []

        // One creature per user — use the most active session's state,
        // or idle if no sessions are running.
        let effective = stateMachine.sessionStore.effectiveSession
        let localReaction = roomManager.localState?.reaction
        let localReactionActive = roomManager.localState?.hasActiveReaction ?? false
        creatures.append(CreatureDisplay(
            id: "local",
            state: effective?.state ?? CreatureState(),
            creatureType: profile?.creatureType ?? .ghost,
            colorPreset: profile?.colorPreset ?? .none,
            xPosition: wanderPosition,
            isLocal: true,
            displayName: profile?.displayName ?? "You",
            sessionDuration: effective.map { Date().timeIntervalSince($0.startedAt) },
            lastToolName: effective?.lastToolName,
            reaction: localReactionActive ? localReaction : nil,
            reactionActive: localReactionActive
        ))

        if let myId = profile?.peerId {
            let remotePeers = roomManager.peerStore.visiblePeers(excludingPeerId: myId)
            for peer in remotePeers {
                creatures.append(CreatureDisplay(
                    id: "remote-\(peer.peerId)",
                    state: CreatureState(
                        task: peer.task,
                        emotion: peer.emotion,
                        lastActivity: peer.timestamp
                    ),
                    creatureType: peer.creatureType,
                    colorPreset: peer.colorPreset,
                    xPosition: roomManager.peerStore.xPosition(for: peer.peerId),
                    isLocal: false,
                    displayName: peer.displayName,
                    reaction: peer.hasActiveReaction ? peer.reaction : nil,
                    reactionActive: peer.hasActiveReaction
                ))
            }
        }

        // Compute facing: each creature faces its nearest neighbor
        return computeFacing(creatures)
    }

    private func computeFacing(_ creatures: [CreatureDisplay]) -> [CreatureDisplay] {
        guard creatures.count > 1 else { return creatures }
        let sorted = creatures.sorted { $0.xPosition < $1.xPosition }
        return creatures.map { c in
            var c = c
            // Find nearest other creature
            if let nearest = sorted.filter({ $0.id != c.id })
                .min(by: { abs($0.xPosition - c.xPosition) < abs($1.xPosition - c.xPosition) }) {
                c.facingRight = nearest.xPosition > c.xPosition
            }
            return c
        }
    }
}
