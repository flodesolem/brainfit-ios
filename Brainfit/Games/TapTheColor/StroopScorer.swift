import Foundation

public struct StroopScore: Sendable, Equatable {
    public let score: Int
    public let correct: Int
    public let incorrect: Int
    public let avgMs: Double

    public init(score: Int, correct: Int, incorrect: Int, avgMs: Double) {
        self.score = score
        self.correct = correct
        self.incorrect = incorrect
        self.avgMs = avgMs
    }
}

public enum StroopScorer {
    public static func score(correct: Int, incorrect: Int, avgMs: Double) -> StroopScore {
        let speedBonus = max(0, 200 - Int(avgMs / 10))
        let raw = correct * 50 - incorrect * 30 + speedBonus
        return StroopScore(
            score: ScoreCalculator.normalize(rawScore: raw),
            correct: correct,
            incorrect: incorrect,
            avgMs: avgMs
        )
    }
}
