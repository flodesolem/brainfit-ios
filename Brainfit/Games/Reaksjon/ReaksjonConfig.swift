import Foundation

public struct ReaksjonConfig: Sendable {
    public let rounds: Int
    public let minDelaySeconds: Double
    public let maxDelaySeconds: Double

    public init(rounds: Int, minDelaySeconds: Double, maxDelaySeconds: Double) {
        self.rounds = rounds
        self.minDelaySeconds = minDelaySeconds
        self.maxDelaySeconds = maxDelaySeconds
    }

    public static func forDifficulty(_ difficulty: Difficulty) -> ReaksjonConfig {
        switch difficulty {
        case .easy:
            return ReaksjonConfig(rounds: 8, minDelaySeconds: 2.0, maxDelaySeconds: 5.0)
        case .medium:
            return ReaksjonConfig(rounds: 10, minDelaySeconds: 1.5, maxDelaySeconds: 4.0)
        case .hard:
            return ReaksjonConfig(rounds: 12, minDelaySeconds: 1.0, maxDelaySeconds: 3.0)
        }
    }
}
