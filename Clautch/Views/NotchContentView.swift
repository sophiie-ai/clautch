import SwiftUI

/// Shared hover state, set by the AppKit tracking area.
@Observable
final class NotchHoverState {
    static let shared = NotchHoverState()
    var isHovered = false
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

    private var isExpanded: Bool { hoverState.isHovered }

    var body: some View {
        GrassIslandView(creatures: allCreatures, isExpanded: isExpanded)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .onAppear { startWandering() }
            .onDisappear { wanderTimer?.invalidate() }
    }

    // MARK: - Wander

    private func startWandering() {
        wanderTimer?.invalidate()
        wanderTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            let newTarget = CGFloat.random(in: 0.05...0.95)
            withAnimation(.easeInOut(duration: 2.5)) {
                wanderPosition = newTarget
            }
        }
    }

    /// Build unified creature list from local sessions + remote peers.
    private var allCreatures: [CreatureDisplay] {
        let profile = UserProfile.current
        var creatures: [CreatureDisplay] = []

        let localSessions = stateMachine.sessionStore.activeSessions
        if !localSessions.isEmpty {
            for session in localSessions {
                creatures.append(CreatureDisplay(
                    id: "local-\(session.id)",
                    state: session.state,
                    creatureType: profile?.creatureType ?? .ghost,
                    colorPreset: profile?.colorPreset ?? .none,
                    xPosition: session.xPosition,
                    isLocal: true,
                    displayName: profile?.displayName ?? "You",
                    sessionDuration: Date().timeIntervalSince(session.startedAt)
                ))
            }
        } else {
            creatures.append(CreatureDisplay(
                id: "local-idle",
                state: CreatureState(),
                creatureType: profile?.creatureType ?? .ghost,
                colorPreset: profile?.colorPreset ?? .none,
                xPosition: wanderPosition,
                isLocal: true,
                displayName: profile?.displayName ?? "You"
            ))
        }

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
                    displayName: peer.displayName
                ))
            }
        }

        return creatures
    }
}
