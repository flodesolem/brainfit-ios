import Foundation
import Observation

public enum ReaksjonPhase: Equatable, Sendable {
    case waiting    // venter — sirkel grå
    case go         // tapp nå — sirkel grønn
    case tooEarly   // false start
    case feedback   // viste reaksjonstid mellom runder
}

@Observable
@MainActor
public final class ReaksjonViewModel {
    public let config: ReaksjonConfig
    public private(set) var phase: ReaksjonPhase = .waiting
    public private(set) var currentRound: Int = 0
    public private(set) var reactionsMs: [Double] = []
    public private(set) var falseStarts: Int = 0
    public private(set) var lastReactionMs: Double?
    public private(set) var isComplete: Bool = false

    private var goAt: Date?
    private var rng: SystemRandomNumberGeneratorBox

    public init(config: ReaksjonConfig, seed: UInt64? = nil) {
        self.config = config
        self.rng = SystemRandomNumberGeneratorBox(seed: seed)
    }

    /// Deterministisk pseudo-random forsinkelse i sekunder, i [minDelaySeconds, maxDelaySeconds].
    public func nextDelay() -> Double {
        let range = config.maxDelaySeconds - config.minDelaySeconds
        // 0.0..<1.0 fra seedet RNG
        let raw = Double(rng.nextUInt64() % 1_000_000) / 1_000_000.0
        return config.minDelaySeconds + raw * range
    }

    public func startWaiting() {
        phase = .waiting
        goAt = nil
        lastReactionMs = nil
    }

    public func goNow() {
        phase = .go
        goAt = Date()
    }

    public func registerTap() {
        switch phase {
        case .waiting:
            falseStarts += 1
            phase = .tooEarly
        case .go:
            if let start = goAt {
                let ms = Date().timeIntervalSince(start) * 1000
                reactionsMs.append(ms)
                lastReactionMs = ms
            }
            phase = .feedback
        case .tooEarly, .feedback:
            // ignorer ekstra taps i mellomfaser
            break
        }
    }

    public func advanceRound() {
        currentRound += 1
        if currentRound >= config.rounds {
            isComplete = true
        } else {
            startWaiting()
        }
    }

    public func finalResult(difficulty: Difficulty) -> GameResult {
        let scored = ReaksjonScorer.score(reactionsMs: reactionsMs, falseStarts: falseStarts)
        let totalAttempts = reactionsMs.count + falseStarts
        let accuracy: Double
        if totalAttempts == 0 {
            accuracy = 0
        } else {
            accuracy = Double(reactionsMs.count) / Double(totalAttempts)
        }
        let avgDelay = (config.minDelaySeconds + config.maxDelaySeconds) / 2
        return GameResult(
            gameId: "reaksjon",
            score: scored.score,
            accuracy: accuracy,
            durationSeconds: Double(config.rounds) * avgDelay,
            difficulty: difficulty,
            rawMetrics: [
                "avgMs": scored.avgMs,
                "bestMs": scored.bestMs,
                "falseStarts": Double(scored.falseStarts)
            ]
        )
    }
}
