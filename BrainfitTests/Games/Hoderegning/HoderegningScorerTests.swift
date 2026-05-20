import XCTest
@testable import Brainfit

final class HoderegningScorerTests: XCTestCase {
    func testAllCorrectGivesHighScore() {
        let result = HoderegningScorer.score(correct: 20, incorrect: 0, avgMs: 800, bestStreak: 20)
        let expectedSpeed = max(0, 60 - Int(800.0 / 50))
        let expectedRaw = 20 * 60 + expectedSpeed * 20
        XCTAssertEqual(result.score, ScoreCalculator.normalize(rawScore: expectedRaw))
        XCTAssertEqual(result.correct, 20)
        XCTAssertEqual(result.bestStreak, 20)
    }

    func testIncorrectAnswersPenalize() {
        // Use values that stay below the 1000 raw-score clamp so the penalty is observable.
        let allCorrect = HoderegningScorer.score(correct: 8, incorrect: 0, avgMs: 1500, bestStreak: 8)
        let withMistakes = HoderegningScorer.score(correct: 8, incorrect: 5, avgMs: 1500, bestStreak: 5)
        XCTAssertLessThan(withMistakes.score, allCorrect.score)
    }

    func testFasterResponsesGiveSpeedBonus() {
        let slow = HoderegningScorer.score(correct: 10, incorrect: 0, avgMs: 2500, bestStreak: 5)
        let fast = HoderegningScorer.score(correct: 10, incorrect: 0, avgMs: 400, bestStreak: 5)
        XCTAssertGreaterThan(fast.score, slow.score)
    }

    func testNegativeRawScoreIsClampedToZero() {
        let result = HoderegningScorer.score(correct: 0, incorrect: 50, avgMs: 1500, bestStreak: 0)
        XCTAssertEqual(result.score, 0)
    }

    func testNormalizedScoreCapsAt1000() {
        let result = HoderegningScorer.score(correct: 200, incorrect: 0, avgMs: 200, bestStreak: 200)
        XCTAssertLessThanOrEqual(result.score, 1000)
    }
}
