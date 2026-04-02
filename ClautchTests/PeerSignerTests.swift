import XCTest
@testable import Clautch

final class PeerSignerTests: XCTestCase {

    func testSignAndVerify() {
        let ts = Date()
        let sig = PeerSigner.sign(peerId: "peer1", task: "idle", emotion: "neutral", timestamp: ts)
        XCTAssertFalse(sig.isEmpty)

        let valid = PeerSigner.verify(
            signature: sig, publicKey: PeerSigner.publicKeyString,
            peerId: "peer1", task: "idle", emotion: "neutral", timestamp: ts
        )
        XCTAssertTrue(valid)
    }

    func testVerifyRejectsTamperedPeerId() {
        let ts = Date()
        let sig = PeerSigner.sign(peerId: "peer1", task: "idle", emotion: "neutral", timestamp: ts)

        let valid = PeerSigner.verify(
            signature: sig, publicKey: PeerSigner.publicKeyString,
            peerId: "attacker", task: "idle", emotion: "neutral", timestamp: ts
        )
        XCTAssertFalse(valid)
    }

    func testVerifyRejectsTamperedTask() {
        let ts = Date()
        let sig = PeerSigner.sign(peerId: "peer1", task: "idle", emotion: "neutral", timestamp: ts)

        let valid = PeerSigner.verify(
            signature: sig, publicKey: PeerSigner.publicKeyString,
            peerId: "peer1", task: "working", emotion: "neutral", timestamp: ts
        )
        XCTAssertFalse(valid)
    }

    func testVerifyRejectsWrongPublicKey() {
        let ts = Date()
        let sig = PeerSigner.sign(peerId: "peer1", task: "idle", emotion: "neutral", timestamp: ts)

        // Use a bogus public key
        let valid = PeerSigner.verify(
            signature: sig, publicKey: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
            peerId: "peer1", task: "idle", emotion: "neutral", timestamp: ts
        )
        XCTAssertFalse(valid)
    }

    func testVerifyRejectsInvalidSignature() {
        let valid = PeerSigner.verify(
            signature: "not-a-sig", publicKey: PeerSigner.publicKeyString,
            peerId: "peer1", task: "idle", emotion: "neutral", timestamp: Date()
        )
        XCTAssertFalse(valid)
    }

    func testPublicKeyIsStable() {
        let key1 = PeerSigner.publicKeyString
        let key2 = PeerSigner.publicKeyString
        XCTAssertEqual(key1, key2)
    }

    func testPublicKeyIsBase64() {
        let key = PeerSigner.publicKeyString
        XCTAssertNotNil(Data(base64Encoded: key))
        XCTAssertEqual(Data(base64Encoded: key)!.count, 32) // Ed25519 public key = 32 bytes
    }
}
