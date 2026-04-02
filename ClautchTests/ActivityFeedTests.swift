import XCTest
@testable import Clautch

@MainActor
final class ActivityFeedTests: XCTestCase {

    func testTimeAgoSeconds() {
        let item = ActivityItem(icon: "▶", text: "test", timestamp: Date())
        let ago = item.timeAgo
        XCTAssertTrue(ago.hasSuffix("s"))
    }

    func testTimeAgoMinutes() {
        let item = ActivityItem(icon: "▶", text: "test", timestamp: Date(timeIntervalSinceNow: -120))
        XCTAssertEqual(item.timeAgo, "2m")
    }

    func testTimeAgoHours() {
        let item = ActivityItem(icon: "▶", text: "test", timestamp: Date(timeIntervalSinceNow: -7200))
        XCTAssertEqual(item.timeAgo, "2h")
    }

    func testTimeAgoBoundary59Seconds() {
        let item = ActivityItem(icon: "▶", text: "test", timestamp: Date(timeIntervalSinceNow: -59))
        XCTAssertEqual(item.timeAgo, "59s")
    }

    func testTimeAgoBoundary60Seconds() {
        let item = ActivityItem(icon: "▶", text: "test", timestamp: Date(timeIntervalSinceNow: -60))
        XCTAssertEqual(item.timeAgo, "1m")
    }

    func testTimeAgoBoundary60Minutes() {
        let item = ActivityItem(icon: "▶", text: "test", timestamp: Date(timeIntervalSinceNow: -3600))
        XCTAssertEqual(item.timeAgo, "1h")
    }
}
