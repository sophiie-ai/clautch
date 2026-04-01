import XCTest
@testable import Clautch

@MainActor
final class SessionStatsTests: XCTestCase {

    func testFormatSeconds() {
        XCTAssertEqual(SessionStats.format(0), "0m")
        XCTAssertEqual(SessionStats.format(59), "0m")
        XCTAssertEqual(SessionStats.format(60), "1m")
        XCTAssertEqual(SessionStats.format(3600), "1h 0m")
        XCTAssertEqual(SessionStats.format(3660), "1h 1m")
        XCTAssertEqual(SessionStats.format(7200), "2h 0m")
    }

    func testActivityItem() {
        let item = ActivityItem(icon: "⚡", text: "test", timestamp: Date())
        XCTAssertEqual(item.timeAgo, "0s")
    }

    func testActivityItemMinutesAgo() {
        let item = ActivityItem(icon: "⚡", text: "test", timestamp: Date().addingTimeInterval(-120))
        XCTAssertEqual(item.timeAgo, "2m")
    }
}
