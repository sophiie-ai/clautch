import Foundation
import CloudKit

/// Observable store of remote peers in the current room.
@Observable
@MainActor
final class PeerStore {
    /// All known peers (including stale ones for fade-out).
    private(set) var peers: [String: PeerState] = [:]

    /// Map peerId → CKRecord.ID for presence updates.
    @ObservationIgnored var recordIDs: [String: CKRecord.ID] = [:]

    /// Stable X positions for each peer (generated once on join, persisted by peerId hash).
    @ObservationIgnored private var positions: [String: CGFloat] = [:]

    /// Peers that should be rendered (active within 5 min, excluding self).
    func visiblePeers(excludingPeerId selfId: String) -> [PeerState] {
        peers.values
            .filter { $0.peerId != selfId && $0.isVisible }
            .sorted { $0.displayName < $1.displayName }
    }

    /// Get or generate a stable X position for a peer.
    func xPosition(for peerId: String) -> CGFloat {
        if let pos = positions[peerId] { return pos }
        // Deterministic position from peer ID hash
        let hash = peerId.utf8.reduce(0) { ($0 &* 31) &+ UInt64($1) }
        let pos = CGFloat(hash % 1000) / 1000.0 * 0.6 + 0.2  // 0.2…0.8
        positions[peerId] = pos
        return pos
    }

    /// Update the store with fresh data from CloudKit.
    /// Detects new reactions, chat messages, joins, and leaves — posts notifications and feeds activity.
    func update(with fetchedPeers: [(CKRecord.ID, PeerState)]) {
        let myId = UserProfile.current?.peerId
        let activity = RoomActivityFeed.shared

        var newPeers: [String: PeerState] = [:]
        var newRecordIDs: [String: CKRecord.ID] = [:]
        var fetchedIds = Set<String>()

        for (recordID, peer) in fetchedPeers {
            fetchedIds.insert(peer.peerId)

            // Detect new reactions/chats/joins from other peers
            if peer.peerId != myId {
                let oldPeer = peers[peer.peerId]

                // New peer joined
                if oldPeer == nil && peer.isActive {
                    activity.addJoin(peer.displayName)
                    NotificationService.shared.playSound(.peerJoin)
                }

                // New reaction that wasn't there before
                if let reaction = peer.reaction, peer.hasActiveReaction,
                   oldPeer?.reaction != reaction {
                    NotificationService.shared.postReactionReceived(
                        from: peer.displayName, reaction: reaction
                    )
                    activity.addReaction(from: peer.displayName, reaction: reaction)
                    NotificationService.shared.playSound(.reactionReceived)
                }

                // New chat message
                if let chat = peer.chatMessage, peer.hasActiveChat,
                   oldPeer?.chatMessage != chat {
                    NotificationService.shared.postChatReceived(
                        from: peer.displayName, message: chat
                    )
                    activity.addChat(from: peer.displayName, message: chat)
                    NotificationService.shared.playSound(.chatReceived)
                }
            }

            newPeers[peer.peerId] = peer
            newRecordIDs[peer.peerId] = recordID
        }

        // Detect peers that left (were visible before, now gone)
        if myId != nil {
            for (peerId, oldPeer) in peers where peerId != myId {
                if oldPeer.isVisible && !fetchedIds.contains(peerId) {
                    activity.addLeave(oldPeer.displayName)
                    NotificationService.shared.playSound(.peerLeave)
                }
            }
        }

        peers = newPeers
        recordIDs = newRecordIDs
    }

    /// Clear all peers (on room leave).
    func clear() {
        peers.removeAll()
        recordIDs.removeAll()
        positions.removeAll()
    }
}
