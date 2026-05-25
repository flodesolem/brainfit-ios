import Foundation

public struct ReaksjonScore: Sendable, Equatable {
    public let score: Int
    public let avgMs: Double
    public let bestMs: Double
    public let falseStarts: Int

    public init(score: Int, avgMs: Double, bestMs: Double, falseStarts: Int) {
        self.score = score
        self.avgMs = avgMs
        self.bestMs = bestMs
        self.falseStarts = falseStarts
    }
}

public enum ReaksjonScorer {
    /// Beregner score basert på reaksjonstider og false starts.
    ///
    /// Hver false start legger til 800ms i gjennomsnittsberegningen.
    /// Hvis det ikke finnes reaksjonstider eller false starts, returneres score=0.
    public static func score(reactionsMs: [Double], falseStarts: Int) -> ReaksjonScore {
        let penalizedTimes = reactionsMs + Array(repeating: 800.0, count: falseStarts)
        let avg: Double
        if penalizedTimes.isEmpty {
            avg = 0
        } else {
            avg = penalizedTimes.reduce(0, +) / Double(penalizedTimes.count)
        }
        let best = reactionsMs.min() ?? 0
        let raw: Int
        if penalizedTimes.isEmpty {
            raw = 0
        } else {
            raw = 1400 - Int(avg * 2)
        }
        return ReaksjonScore(
            score: ScoreCalculator.normalize(rawScore: raw),
            avgMs: avg,
            bestMs: best,
            falseStarts: falseStarts
        )
    }
}
