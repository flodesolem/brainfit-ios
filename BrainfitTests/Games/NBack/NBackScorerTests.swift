import XCTest
@testable import Brainfit

final class NBackScorerTests: XCTestCase {
    func testPerfectPlayScores1000() {
        let result = NBackScorer.score(targets: 5, nonTargets: 15, hits: 5, falseAlarms: 0, avgReactionMs: 600)
        XCTAssertEqual(result.score, 1000)
        XCTAssertEqual(result.misses, 0)
        XCTAssertEqual(result.correctRejections, 15)
    }

    func testAllMissesAndNoFalseAlarmsScoresZero() {
        let result = NBackScorer.score(targets: 5, nonTargets: 15, hits: 0, falseAlarms: 0, avgReactionMs: 0)
        XCTAssertEqual(result.score, 0)
        XCTAssertEqual(result.misses, 5)
    }

    func testFalseAlarmsReduceScore() {
        let result = NBackScorer.score(targets: 5, nonTargets: 15, hits: 5, falseAlarms: 5, avgReactionMs: 600)
        XCTAssertLessThan(result.score, 1000)
        XCTAssertGreaterThan(result.score, 0)
    }

    func testZeroTargetsCountsRejectionsOnly() {
        let result = NBackScorer.score(targets: 0, nonTargets: 20, hits: 0, falseAlarms: 0, avgReactionMs: 0)
        XCTAssertEqual(result.score, 1000)
    }
}
