import XCTest
@testable import Clautch

final class RoomInfoTests: XCTestCase {

    func testGenerateCodeLength() {
        let code = RoomInfo.generateCode()
        XCTAssertEqual(code.count, 6)
    }

    func testGenerateCodeCharacters() {
        let allowed = Set("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        for _ in 0..<100 {
            let code = RoomInfo.generateCode()
            for char in code {
                XCTAssertTrue(allowed.contains(char), "Code contains invalid character: \(char)")
            }
        }
    }

    func testGenerateCodeUniqueness() {
        let codes = (0..<50).map { _ in RoomInfo.generateCode() }
        let unique = Set(codes)
        // With 30^6 possibilities, 50 codes should all be unique
        XCTAssertEqual(codes.count, unique.count)
    }

    func testGenerateInviteToken() {
        let token = RoomInfo.generateInviteToken()
        XCTAssertEqual(token.count, 16) // 16 bytes → 16 Base62 chars
    }

    func testParseShareableCodeBare() {
        let (code, token) = RoomInfo.parse(shareableCode: "ABCDEF")
        XCTAssertEqual(code, "ABCDEF")
        XCTAssertNil(token)
    }

    func testParseShareableCodeWithToken() {
        let (code, token) = RoomInfo.parse(shareableCode: "ABCDEF-mySecretToken123")
        XCTAssertEqual(code, "ABCDEF")
        XCTAssertEqual(token, "mySecretToken123")
    }

    func testParseShareableCodeLowercase() {
        let (code, _) = RoomInfo.parse(shareableCode: "abcdef")
        XCTAssertEqual(code, "ABCDEF")
    }

    func testParseShareableCodeWithWhitespace() {
        let (code, _) = RoomInfo.parse(shareableCode: "  ABCDEF  ")
        XCTAssertEqual(code, "ABCDEF")
    }

    func testShareableCodeRoundtrip() {
        let room = RoomInfo(
            roomCode: "HK3WPR",
            inviteToken: "abc123",
            createdAt: Date(),
            creatorPeerId: "peer1"
        )
        let (code, token) = RoomInfo.parse(shareableCode: room.shareableCode)
        XCTAssertEqual(code, "HK3WPR")
        XCTAssertEqual(token, "abc123")
    }
}
