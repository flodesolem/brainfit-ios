import Foundation

public enum ScoreCalculator {
    public static func normalize(rawScore: Int) -> Int {
        max(0, min(1000, rawScore))
    }

    public static func averageScore(runs: [Int]) -> Int {
        guard !runs.isEmpty else { return 0 }
        return runs.reduce(0, +) / runs.count
    }

    public static func recommendDifficulty(currentLevel: Difficulty, recentScores: [Int]) -> Difficulty {
        guard !recentScores.isEmpty else { return currentLevel }
        let avg = averageScore(runs: recentScores)
        if avg > 700 { return currentLevel.bumped(by: 1) }
        if avg < 400 { return currentLevel.bumped(by: -1) }
        return currentLevel
    }
}
