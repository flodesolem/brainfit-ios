import XCTest
@testable import Brainfit

final class GameTypesTests: XCTestCase {
    func testDifficultyRawValues() {
        XCTAssertEqual(Difficulty.easy.rawValue, 1)
        XCTAssertEqual(Difficulty.medium.rawValue, 2)
        XCTAssertEqual(Difficulty.hard.rawValue, 3)
    }

    func testDifficultyRoundTripsThroughCodable() throws {
        let data = try JSONEncoder().encode(Difficulty.hard)
        let decoded = try JSONDecoder().decode(Difficulty.self, from: data)
        XCTAssertEqual(decoded, .hard)
    }

    func testGameCategoryHasAllExpectedCases() {
        let all: Set<GameCategory> = [.memory, .reaction, .attention, .language, .math, .problemSolving]
        XCTAssertEqual(all.count, 6)
    }
}
