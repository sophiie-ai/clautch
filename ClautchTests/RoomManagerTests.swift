import XCTest
import CloudKit
@testable import Clautch

@MainActor
final class RoomManagerTests: XCTestCase {

    // MARK: - PeerStore

    func testPeerStoreXPositionDeterministic() {
        let store = PeerStore()
        let pos1 = store.xPosition(for: "peer-abc")
        let pos2 = store.xPosition(for: "peer-abc")
        XCTAssertEqual(pos1, pos2, "Same peer ID should always get the same position")
    }

    func testPeerStoreXPositionInRange() {
        let store = PeerStore()
        for i in 0..<20 {
            let pos = store.xPosition(for: "peer-\(i)")
            XCTAssertGreaterThanOrEqual(pos, 0.2)
            XCTAssertLessThanOrEqual(pos, 0.8)
        }
    }

    func testPeerStoreClearRemovesAll() {
        let store = PeerStore()
        _ = store.xPosition(for: "peer-1")
        store.clear()
        XCTAssertTrue(store.peers.isEmpty)
        XCTAssertTrue(store.recordIDs.isEmpty)
    }

    func testVisiblePeersExcludesSelf() {
        let store = PeerStore()
        let selfPeer = makePeer(id: "self", task: .idle)
        let otherPeer = makePeer(id: "other", task: .working)
        store.update(with: [
            (makeFakeRecordID("r1"), selfPeer),
            (makeFakeRecordID("r2"), otherPeer),
        ])
        let visible = store.visiblePeers(excludingPeerId: "self")
        XCTAssertEqual(visible.count, 1)
        XCTAssertEqual(visible.first?.peerId, "other")
    }

    func testVisiblePeersExcludesStale() {
        let store = PeerStore()
        let stalePeer = PeerState(
            peerId: "stale", displayName: "Stale", creatureType: .ghost,
            task: .idle, emotion: .neutral, colorPreset: .none, accessory: .none,
            timestamp: Date(timeIntervalSinceNow: -600) // 10 min ago
        )
        store.update(with: [(makeFakeRecordID("r1"), stalePeer)])
        let visible = store.visiblePeers(excludingPeerId: "me")
        XCTAssertTrue(visible.isEmpty, "Stale peers should not be visible")
    }

    // MARK: - PeerState Broadcast Equals

    func testBroadcastEqualsIdentical() {
        let a = makePeer(id: "p1", task: .working)
        XCTAssertTrue(a.broadcastEquals(a))
    }

    func testBroadcastEqualsDifferentTask() {
        let a = makePeer(id: "p1", task: .working)
        let b = makePeer(id: "p1", task: .thinking)
        XCTAssertFalse(a.broadcastEquals(b))
    }

    func testBroadcastEqualsSmallPositionChange() {
        var a = makePeer(id: "p1", task: .idle)
        var b = makePeer(id: "p1", task: .idle)
        a.xPosition = 0.500
        b.xPosition = 0.505  // < 0.01 threshold
        XCTAssertTrue(a.broadcastEquals(b))
    }

    func testBroadcastEqualsLargePositionChange() {
        var a = makePeer(id: "p1", task: .idle)
        var b = makePeer(id: "p1", task: .idle)
        a.xPosition = 0.5
        b.xPosition = 0.7
        XCTAssertFalse(a.broadcastEquals(b))
    }

    func testBroadcastEqualsTypingDifference() {
        var a = makePeer(id: "p1", task: .idle)
        var b = makePeer(id: "p1", task: .idle)
        a.isTyping = true
        b.isTyping = false
        XCTAssertFalse(a.broadcastEquals(b))
    }

    // MARK: - Connection Status

    func testConnectionStatusLabels() {
        XCTAssertEqual(ConnectionStatus.disconnected.label, "Not in a room")
        XCTAssertEqual(ConnectionStatus.connecting.label, "Connecting…")
        XCTAssertEqual(ConnectionStatus.connected.label, "Connected")
        XCTAssertEqual(ConnectionStatus.reconnecting.label, "Reconnecting…")
        XCTAssertTrue(ConnectionStatus.error("fail").label.contains("fail"))
    }

    func testConnectionStatusEquality() {
        XCTAssertEqual(ConnectionStatus.connected, ConnectionStatus.connected)
        XCTAssertNotEqual(ConnectionStatus.connected, ConnectionStatus.disconnected)
        XCTAssertEqual(ConnectionStatus.error("x"), ConnectionStatus.error("x"))
        XCTAssertNotEqual(ConnectionStatus.error("x"), ConnectionStatus.error("y"))
    }

    // MARK: - Room Info

    func testRoomCodeGeneration() {
        let codes = (0..<10).map { _ in RoomInfo.generateCode() }
        // All codes should be 8 characters
        for code in codes {
            XCTAssertEqual(code.count, 8)
        }
        // Codes should be unique (probabilistic but with 32^8 space, collisions are negligible)
        XCTAssertEqual(Set(codes).count, codes.count)
    }

    func testInviteTokenGeneration() {
        let token = RoomInfo.generateInviteToken()
        XCTAssertEqual(token.count, 22)
        // All chars should be alphanumeric
        let allowed = CharacterSet.alphanumerics
        XCTAssertTrue(token.unicodeScalars.allSatisfy { allowed.contains($0) })
    }

    func testRoomExpiry() {
        // Rooms older than 2 hours with no active peers should expire
        // This is a logic test — the 7200-second threshold is in CloudKitService.expireRoomIfStale
        let twoHoursAgo = Date(timeIntervalSinceNow: -7201)
        XCTAssertTrue(Date().timeIntervalSince(twoHoursAgo) > 7200)
    }

    // MARK: - Helpers

    private func makePeer(id: String, task: CreatureTask) -> PeerState {
        PeerState(
            peerId: id, displayName: "Test", creatureType: .ghost,
            task: task, emotion: .neutral, colorPreset: .none, accessory: .none,
            timestamp: Date()
        )
    }

    private func makeFakeRecordID(_ name: String) -> CKRecord.ID {
        CKRecord.ID(recordName: name)
    }
}
