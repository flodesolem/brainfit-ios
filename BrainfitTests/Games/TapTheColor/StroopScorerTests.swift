import XCTest
@testable import Brainfit

final class StroopScorerTests: XCTestCase {
    func testAllCorrectGivesHighScore() {
        let result = StroopScorer.score(correct: 20, incorrect: 0, avgMs: 800)
        XCTAssertEqual(result.score, ScoreCalculator.normalize(rawScore: 20 * 50 + max(0, 200 - 80)))
    }

    func testIncorrectAnswersPenalize() {
        let allCorrect = StroopScorer.score(correct: 20, incorrect: 0, avgMs: 800)
        let withMistakes = StroopScorer.score(correct: 20, incorrect: 5, avgMs: 800)
        XCTAssertLessThan(withMistakes.score, allCorrect.score)
    }

    func testFasterResponsesGiveSpeedBonus() {
        let slow = StroopScorer.score(correct: 10, incorrect: 0, avgMs: 1500)
        let fast = StroopScorer.score(correct: 10, incorrect: 0, avgMs: 600)
        XCTAssertGreaterThan(fast.score, slow.score)
    }

    func testNegativeRawScoreIsClampedToZero() {
        let result = StroopScorer.score(correct: 0, incorrect: 50, avgMs: 1500)
        XCTAssertEqual(result.score, 0)
    }
}
