import XCTest
@testable import Clautch

final class CreatureStateTests: XCTestCase {

    func testDefaultState() {
        let state = CreatureState()
        XCTAssertEqual(state.task, .idle)
        XCTAssertEqual(state.emotion, .neutral)
    }

    func testIsActiveRecentActivity() {
        var state = CreatureState()
        state.lastActivity = Date()
        XCTAssertTrue(state.isActive)
    }

    func testIsActiveStaleActivity() {
        var state = CreatureState()
        state.lastActivity = Date().addingTimeInterval(-120)
        XCTAssertFalse(state.isActive)
    }

    func testTaskDisplayLabels() {
        XCTAssertEqual(CreatureTask.idle.displayLabel, "Idle")
        XCTAssertEqual(CreatureTask.working.displayLabel, "Working")
        XCTAssertEqual(CreatureTask.thinking.displayLabel, "Thinking")
        XCTAssertEqual(CreatureTask.sleeping.displayLabel, "Sleeping")
        XCTAssertEqual(CreatureTask.compacting.displayLabel, "Compacting")
    }

    func testTaskBobAmplitude() {
        XCTAssertEqual(CreatureTask.sleeping.bobAmplitude, 0.0)
        XCTAssertGreaterThan(CreatureTask.idle.bobAmplitude, 0)
    }

    func testTaskFPS() {
        XCTAssertGreaterThan(CreatureTask.working.fps, CreatureTask.sleeping.fps)
    }
}
