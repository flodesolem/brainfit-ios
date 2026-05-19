import XCTest
@testable import Brainfit

final class ScoreCalculatorTests: XCTestCase {
    func testNormalizeClampsAbove1000() {
        XCTAssertEqual(ScoreCalculator.normalize(rawScore: 1500), 1000)
    }

    func testNormalizeClampsBelow0() {
        XCTAssertEqual(ScoreCalculator.normalize(rawScore: -10), 0)
    }

    func testAverageReturnsZeroForEmpty() {
        XCTAssertEqual(ScoreCalculator.averageScore(runs: []), 0)
    }

    func testAverageRoundsDown() {
        XCTAssertEqual(ScoreCalculator.averageScore(runs: [100, 200, 301]), 200)
    }
}
