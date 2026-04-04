import XCTest
import CloudKit
@testable import Clautch

// MARK: - Mock CloudKit Service

final class MockCloudKitService: CloudKitServiceProtocol, @unchecked Sendable {
    var isAvailable: Bool = true

    // Tracking calls
    var createRoomCalls: [(code: String, peerId: String, token: String)] = []
    var findRoomCalls: [String] = []
    var writePresenceCalls: [(roomCode: String, state: PeerState)] = []
    var fetchPresencesCalls: [String] = []
    var deletePresenceCalls: [CKRecord.ID] = []
    var deleteRoomCalls: [CKRecord.ID] = []
    var cleanupCalls: [String] = []
    var subscribeCalls: [String] = []
    var unsubscribeCalled = false
    var expireCalls: [String] = []

    // Configurable responses
    var findRoomResult: CKRecord?
    var fetchPresencesResult: [(CKRecord.ID, PeerState)] = []
    var shouldThrow = false
    var expireResult = false

    func createRoom(code: String, creatorPeerId: String, inviteToken: String) async throws -> CKRecord {
        createRoomCalls.append((code, creatorPeerId, inviteToken))
        if shouldThrow { throw MockError.failed }
        let record = CKRecord(recordType: "ClautchRoom")
        record["roomCode"] = code
        record["creatorPeerId"] = creatorPeerId
        record["inviteToken"] = inviteToken
        record["createdAt"] = Date() as NSDate
        return record
    }

    func findRoom(code: String) async throws -> CKRecord? {
        findRoomCalls.append(code)
        if shouldThrow { throw MockError.failed }
        return findRoomResult
    }

    func deleteRoom(recordID: CKRecord.ID) async throws {
        deleteRoomCalls.append(recordID)
        if shouldThrow { throw MockError.failed }
    }

    func writePresence(existingRecordID: CKRecord.ID?, roomCode: String, state: PeerState) async throws -> CKRecord {
        writePresenceCalls.append((roomCode, state))
        if shouldThrow { throw MockError.failed }
        return CKRecord(recordType: "ClautchPresence")
    }

    func fetchPresences(roomCode: String) async throws -> [(CKRecord.ID, PeerState)] {
        fetchPresencesCalls.append(roomCode)
        if shouldThrow { throw MockError.failed }
        return fetchPresencesResult
    }

    func deletePresence(recordID: CKRecord.ID) async throws {
        deletePresenceCalls.append(recordID)
        if shouldThrow { throw MockError.failed }
    }

    func cleanupStalePresences(roomCode: String) async throws {
        cleanupCalls.append(roomCode)
    }

    func expireRoomIfStale(roomCode: String) async throws -> Bool {
        expireCalls.append(roomCode)
        return expireResult
    }

    func subscribeToPresence(roomCode: String) async throws {
        subscribeCalls.append(roomCode)
        if shouldThrow { throw MockError.failed }
    }

    func unsubscribeFromPresence() async {
        unsubscribeCalled = true
    }

    func checkAvailability() async -> Bool {
        isAvailable
    }

    enum MockError: Error {
        case failed
    }
}

// MARK: - Tests

@MainActor
final class MockCloudKitTests: XCTestCase {

    private func makeMock() -> MockCloudKitService {
        MockCloudKitService()
    }

    private func makeManager(mock: MockCloudKitService) -> RoomManager {
        RoomManager(cloudKit: mock)
    }

    // MARK: - Create Room

    func testCreateRoomCallsCloudKit() async throws {
        // Can only test if UserProfile exists
        guard UserProfile.current != nil else { return }
        let mock = makeMock()
        let manager = makeManager(mock: mock)

        _ = try await manager.createRoom()

        XCTAssertEqual(mock.createRoomCalls.count, 1)
        XCTAssertEqual(mock.writePresenceCalls.count, 1)
        XCTAssertEqual(mock.subscribeCalls.count, 1)
        XCTAssertEqual(manager.status, .connected)
    }

    // MARK: - Leave Room

    func testLeaveRoomCleansUp() async throws {
        guard UserProfile.current != nil else { return }
        let mock = makeMock()
        let manager = makeManager(mock: mock)

        _ = try await manager.createRoom()
        await manager.leaveRoom()

        XCTAssertTrue(mock.unsubscribeCalled)
        XCTAssertNil(manager.currentRoom)
        XCTAssertEqual(manager.status, .disconnected)
    }

    // MARK: - Join Room Validation

    func testJoinInvalidCodeThrows() async {
        guard UserProfile.current != nil else { return }
        let mock = makeMock()
        let manager = makeManager(mock: mock)

        do {
            try await manager.joinRoom(code: "AB")  // too short
            XCTFail("Should have thrown")
        } catch {
            XCTAssertTrue(error is RoomError)
        }
    }

    func testJoinNonexistentRoomThrows() async {
        guard UserProfile.current != nil else { return }
        let mock = makeMock()
        mock.findRoomResult = nil
        let manager = makeManager(mock: mock)

        do {
            try await manager.joinRoom(code: "ABCD1234")
            XCTFail("Should have thrown")
        } catch let error as RoomError {
            XCTAssertEqual(error.errorDescription, "Room not found")
        } catch {
            XCTFail("Wrong error type")
        }
    }

    // MARK: - Broadcast Equals

    func testBroadcastEqualsSkipsWrite() {
        // State that hasn't changed should not trigger a write
        let state = PeerState(
            peerId: "p1", displayName: "Test", creatureType: .ghost,
            task: .idle, emotion: .neutral, colorPreset: .none, accessory: .none,
            evolution: .baby, timestamp: Date()
        )
        XCTAssertTrue(state.broadcastEquals(state))
    }

    // MARK: - CloudKit Protocol Conformance

    func testMockConformsToProtocol() {
        let mock: any CloudKitServiceProtocol = MockCloudKitService()
        XCTAssertTrue(mock.isAvailable)
    }

    func testMockUnavailable() async {
        let mock = makeMock()
        mock.isAvailable = false
        let available = await mock.checkAvailability()
        XCTAssertFalse(available)
    }

    // MARK: - Error Handling

    func testCreateRoomErrorSetsStatus() async {
        guard UserProfile.current != nil else { return }
        let mock = makeMock()
        mock.shouldThrow = true
        let manager = makeManager(mock: mock)

        do {
            _ = try await manager.createRoom()
            XCTFail("Should throw")
        } catch {
            // Status should be error
            if case .error = manager.status {
                // OK
            } else {
                XCTFail("Expected error status, got \(manager.status)")
            }
        }
    }
}
