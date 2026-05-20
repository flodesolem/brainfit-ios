import Foundation

public struct HoderegningScore: Sendable, Equatable {
    public let score: Int
    public let correct: Int
    public let incorrect: Int
    public let avgMs: Double
    public let bestStreak: Int

    public init(score: Int, correct: Int, incorrect: Int, avgMs: Double, bestStreak: Int) {
        self.score = score
        self.correct = correct
        self.incorrect = incorrect
        self.avgMs = avgMs
        self.bestStreak = bestStreak
    }
}

public enum HoderegningScorer {
    public static func score(correct: Int,
                             incorrect: Int,
                             avgMs: Double,
                             bestStreak: Int) -> HoderegningScore {
        let speedComponent = max(0, 60 - Int(avgMs / 50))
        let speedBonus = correct > 0 ? speedComponent * correct : 0
        let raw = correct * 60 - incorrect * 25 + speedBonus
        return HoderegningScore(
            score: ScoreCalculator.normalize(rawScore: raw),
            correct: correct,
            incorrect: incorrect,
            avgMs: avgMs,
            bestStreak: bestStreak
        )
    }
}
