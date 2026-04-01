import XCTest
@testable import Clautch

final class CreatureTypeTests: XCTestCase {

    func testAllCreaturesHaveTwoFrames() {
        for type in CreatureType.allCases {
            XCTAssertEqual(type.frames.count, 2, "\(type.rawValue) should have 2 idle frames")
        }
    }

    func testAllCreaturesHaveTwoWalkFrames() {
        for type in CreatureType.allCases {
            XCTAssertEqual(type.walkFrames.count, 2, "\(type.rawValue) should have 2 walk frames")
        }
    }

    func testFramesAre8x8() {
        for type in CreatureType.allCases {
            for (i, frame) in type.frames.enumerated() {
                XCTAssertEqual(frame.count, 8, "\(type.rawValue) frame \(i) should have 8 rows")
                for (r, row) in frame.enumerated() {
                    XCTAssertEqual(row.count, 8, "\(type.rawValue) frame \(i) row \(r) should have 8 cols")
                }
            }
        }
    }

    func testPixelCodesAreValid() {
        let validCodes = Set(0...5)
        for type in CreatureType.allCases {
            for frame in type.frames {
                for row in frame {
                    for cell in row {
                        XCTAssertTrue(validCodes.contains(cell),
                            "\(type.rawValue) has invalid pixel code \(cell)")
                    }
                }
            }
        }
    }

    func testAccessoryPixelArt() {
        for acc in CreatureAccessory.allCases {
            if acc == .none {
                XCTAssertNil(acc.pixels)
            } else {
                let pixels = acc.pixels
                XCTAssertNotNil(pixels, "\(acc.rawValue) should have pixel art")
                XCTAssertEqual(pixels?.count, 3, "\(acc.rawValue) should have 3 rows")
                for row in pixels ?? [] {
                    XCTAssertEqual(row.count, 4, "\(acc.rawValue) should have 4 cols")
                }
            }
        }
    }

    func testColorPresetsHaveTintExceptNone() {
        XCTAssertNil(CreatureColorPreset.none.tintColor)
        for preset in CreatureColorPreset.allCases where preset != .none {
            XCTAssertNotNil(preset.tintColor, "\(preset.rawValue) should have a tint color")
        }
    }
}
