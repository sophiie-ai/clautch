import SwiftUI

/// Root view rendered inside the notch panel.
/// Combines local sessions and remote peers into a unified creature display.
struct NotchContentView: View {
    @State private var stateMachine = StateMachine.shared
    @State private var roomManager = RoomManager.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            GrassIslandView(creatures: allCreatures)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    /// Build unified creature list from local sessions + remote peers.
    private var allCreatures: [CreatureDisplay] {
        let profile = UserProfile.current
        var creatures: [CreatureDisplay] = []

        // Local sessions
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
                    displayName: profile?.displayName ?? "You"
                ))
            }
        } else {
            // Always show at least the local creature
            creatures.append(CreatureDisplay(
                id: "local-idle",
                state: CreatureState(),
                creatureType: profile?.creatureType ?? .ghost,
                colorPreset: profile?.colorPreset ?? .none,
                xPosition: 0.5,
                isLocal: true,
                displayName: profile?.displayName ?? "You"
            ))
        }

        // Remote peers
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
