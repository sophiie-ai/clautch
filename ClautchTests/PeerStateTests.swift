import XCTest
@testable import Clautch

final class PeerStateTests: XCTestCase {

    func testIsActiveRecent() {
        let peer = makePeer(timestamp: Date())
        XCTAssertTrue(peer.isActive)
    }

    func testIsActiveStale() {
        let peer = makePeer(timestamp: Date().addingTimeInterval(-120))
        XCTAssertFalse(peer.isActive)
    }

    func testIsVisibleWithin5Min() {
        let peer = makePeer(timestamp: Date().addingTimeInterval(-200))
        XCTAssertFalse(peer.isActive)
        XCTAssertTrue(peer.isVisible)
    }

    func testIsVisibleExpired() {
        let peer = makePeer(timestamp: Date().addingTimeInterval(-400))
        XCTAssertFalse(peer.isVisible)
    }

    func testHasActiveReaction() {
        var peer = makePeer()
        peer.reaction = .heart
        peer.reactionTimestamp = Date()
        XCTAssertTrue(peer.hasActiveReaction)
    }

    func testReactionExpired() {
        var peer = makePeer()
        peer.reaction = .heart
        peer.reactionTimestamp = Date().addingTimeInterval(-10)
        XCTAssertFalse(peer.hasActiveReaction)
    }

    func testHasActiveChat() {
        var peer = makePeer()
        peer.chatMessage = "Hello!"
        peer.chatTimestamp = Date()
        XCTAssertTrue(peer.hasActiveChat)
        XCTAssertEqual(peer.activeChatMessage, "Hello!")
    }

    func testChatExpired() {
        var peer = makePeer()
        peer.chatMessage = "Hello!"
        peer.chatTimestamp = Date().addingTimeInterval(-20)
        XCTAssertFalse(peer.hasActiveChat)
        XCTAssertNil(peer.activeChatMessage)
    }

    func testReactionPixelArt() {
        for reaction in PeerReaction.allCases {
            XCTAssertEqual(reaction.pixels.count, 5, "\(reaction.rawValue) should have 5 rows")
            for row in reaction.pixels {
                XCTAssertEqual(row.count, 5, "\(reaction.rawValue) should have 5 cols")
            }
        }
    }

    // MARK: - Helpers

    private func makePeer(timestamp: Date = Date()) -> PeerState {
        PeerState(
            peerId: "test",
            displayName: "Test",
            creatureType: .ghost,
            task: .idle,
            emotion: .neutral,
            colorPreset: .none,
            accessory: .none,
            evolution: .baby,
            timestamp: timestamp
        )
    }
}
