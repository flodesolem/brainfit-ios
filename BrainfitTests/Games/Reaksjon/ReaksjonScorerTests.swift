import XCTest
@testable import Brainfit

final class ReaksjonScorerTests: XCTestCase {
    func testFastReactionsGiveHighScore() {
        let reactions = Array(repeating: 250.0, count: 10)
        let result = ReaksjonScorer.score(reactionsMs: reactions, falseStarts: 0)
        // raw = 1400 - 500 = 900
        XCTAssertEqual(result.score, 900)
        XCTAssertEqual(result.avgMs, 250, accuracy: 0.001)
        XCTAssertEqual(result.bestMs, 250, accuracy: 0.001)
        XCTAssertEqual(result.falseStarts, 0)
    }

    func testSlowReactionsGiveZeroScore() {
        let reactions = Array(repeating: 700.0, count: 10)
        let result = ReaksjonScorer.score(reactionsMs: reactions, falseStarts: 0)
        // raw = 1400 - 1400 = 0
        XCTAssertEqual(result.score, 0)
    }

    func testFalseStartsPenalizeScore() {
        let reactions = Array(repeating: 300.0, count: 8)
        let clean = ReaksjonScorer.score(reactionsMs: reactions, falseStarts: 0)
        let withFalseStarts = ReaksjonScorer.score(reactionsMs: reactions, falseStarts: 2)
        XCTAssertGreaterThan(clean.score, withFalseStarts.score)
        XCTAssertEqual(withFalseStarts.falseStarts, 2)
    }

    func testEmptyInputGivesZeroScore() {
        let result = ReaksjonScorer.score(reactionsMs: [], falseStarts: 0)
        XCTAssertEqual(result.score, 0)
        XCTAssertEqual(result.bestMs, 0)
    }

    func testBestMsIsMinOfReactions() {
        let reactions: [Double] = [400, 250, 300, 350]
        let result = ReaksjonScorer.score(reactionsMs: reactions, falseStarts: 0)
        XCTAssertEqual(result.bestMs, 250, accuracy: 0.001)
    }

    func testScoreClampedAtThousand() {
        // Ekstrem reaksjonstid: 0 ms ville gi raw 1400 → klampes til 1000
        let reactions = Array(repeating: 0.0, count: 5)
        let result = ReaksjonScorer.score(reactionsMs: reactions, falseStarts: 0)
        XCTAssertLessThanOrEqual(result.score, 1000)
        XCTAssertEqual(result.score, 1000)
    }

    func testFalseStartContributes800MsToAverage() {
        let reactions: [Double] = [400, 400]
        let result = ReaksjonScorer.score(reactionsMs: reactions, falseStarts: 1)
        // avg = (400 + 400 + 800) / 3 = 533.33
        XCTAssertEqual(result.avgMs, (400 + 400 + 800) / 3, accuracy: 0.001)
    }
}
