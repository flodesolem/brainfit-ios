import Foundation

public struct NBackScore: Sendable, Equatable {
    public let score: Int
    public let hits: Int
    public let misses: Int
    public let falseAlarms: Int
    public let correctRejections: Int
    public let avgReactionMs: Double

    public init(score: Int,
                hits: Int,
                misses: Int,
                falseAlarms: Int,
                correctRejections: Int,
                avgReactionMs: Double) {
        self.score = score
        self.hits = hits
        self.misses = misses
        self.falseAlarms = falseAlarms
        self.correctRejections = correctRejections
        self.avgReactionMs = avgReactionMs
    }
}

public enum NBackScorer {
    public static func score(targets: Int,
                             nonTargets: Int,
                             hits: Int,
                             falseAlarms: Int,
                             avgReactionMs: Double) -> NBackScore {
        let misses = max(0, targets - hits)
        let correctRejections = max(0, nonTargets - falseAlarms)
        let accuracy: Double
        if targets == 0 {
            accuracy = nonTargets == 0 ? 1.0 : Double(correctRejections) / Double(nonTargets)
        } else {
            let hitRate = Double(hits) / Double(targets)
            let faRate = nonTargets == 0 ? 0 : Double(falseAlarms) / Double(nonTargets)
            accuracy = max(0, hitRate * (1 - faRate))
        }
        let raw = Int((accuracy * 1000).rounded())
        return NBackScore(
            score: ScoreCalculator.normalize(rawScore: raw),
            hits: hits,
            misses: misses,
            falseAlarms: falseAlarms,
            correctRejections: correctRejections,
            avgReactionMs: avgReactionMs
        )
    }
}
