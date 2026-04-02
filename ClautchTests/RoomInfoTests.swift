import XCTest
@testable import Clautch

final class RoomInfoTests: XCTestCase {

    func testGenerateCodeLength() {
        let code = RoomInfo.generateCode()
        XCTAssertEqual(code.count, 8)
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
        // With 32^8 possibilities, 50 codes should all be unique
        XCTAssertEqual(codes.count, unique.count)
    }

    func testGenerateInviteToken() {
        let token = RoomInfo.generateInviteToken()
        XCTAssertEqual(token.count, 22)
    }

    // MARK: - Parse (8-char codes)

    func testParseShareableCodeBare() {
        let (code, token) = RoomInfo.parse(shareableCode: "ABCDEFGH")
        XCTAssertEqual(code, "ABCDEFGH")
        XCTAssertNil(token)
    }

    func testParseShareableCodeWithToken() {
        let (code, token) = RoomInfo.parse(shareableCode: "ABCDEFGH-mySecretToken123")
        XCTAssertEqual(code, "ABCDEFGH")
        XCTAssertEqual(token, "mySecretToken123")
    }

    func testParseShareableCodeLowercase() {
        let (code, _) = RoomInfo.parse(shareableCode: "abcdefgh")
        XCTAssertEqual(code, "ABCDEFGH")
    }

    func testParseShareableCodeWithWhitespace() {
        let (code, _) = RoomInfo.parse(shareableCode: "  ABCDEFGH  ")
        XCTAssertEqual(code, "ABCDEFGH")
    }

    func testShareableCodeRoundtrip() {
        let room = RoomInfo(
            roomCode: "HK3WPRXY",
            inviteToken: "abc123",
            createdAt: Date(),
            creatorPeerId: "peer1"
        )
        let (code, token) = RoomInfo.parse(shareableCode: room.shareableCode)
        XCTAssertEqual(code, "HK3WPRXY")
        XCTAssertEqual(token, "abc123")
    }

    // MARK: - Legacy 6-char codes

    func testParseLegacyBareCode() {
        let (code, token) = RoomInfo.parse(shareableCode: "ABCDEF")
        XCTAssertEqual(code, "ABCDEF")
        XCTAssertNil(token)
    }

    func testParseLegacyCodeWithToken() {
        let (code, token) = RoomInfo.parse(shareableCode: "ABCDEF-oldToken")
        XCTAssertEqual(code, "ABCDEF")
        XCTAssertEqual(token, "oldToken")
    }
}
