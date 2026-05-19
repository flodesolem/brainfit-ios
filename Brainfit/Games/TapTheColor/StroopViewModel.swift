import Foundation
import Observation

public struct StroopStimulus: Identifiable, Sendable {
    public let id = UUID()
    public let word: StroopColor   // ordet som vises
    public let inkColor: StroopColor // fargen ordet tegnes i
    public var isCongruent: Bool { word == inkColor }
}

@Observable
@MainActor
public final class StroopViewModel {
    public let config: StroopConfig
    public let options: [StroopColor]
    public private(set) var currentStimulus: StroopStimulus
    public private(set) var correct: Int = 0
    public private(set) var incorrect: Int = 0
    public private(set) var responses: [Double] = []
    public private(set) var isComplete: Bool = false
    private var stimulusStart: Date

    private var rng: SystemRandomNumberGeneratorBox
    private let allOptions: [StroopColor]

    public init(config: StroopConfig, seed: UInt64? = nil) {
        self.config = config
        var prng = SystemRandomNumberGeneratorBox(seed: seed)
        let pool = Array(StroopColor.allCases.prefix(config.optionCount))
        self.allOptions = pool
        self.options = pool
        let word = pool[Int(prng.nextUInt64() % UInt64(pool.count))]
        let ink = pool[Int(prng.nextUInt64() % UInt64(pool.count))]
        self.rng = prng
        self.currentStimulus = StroopStimulus(word: word, inkColor: ink)
        self.stimulusStart = Date()
    }

    public func registerAnswer(_ chosen: StroopColor) {
        let ms = Date().timeIntervalSince(stimulusStart) * 1000
        responses.append(ms)
        if chosen == currentStimulus.inkColor {
            correct += 1
        } else {
            incorrect += 1
        }
        nextStimulus()
    }

    public func markComplete() {
        isComplete = true
    }

    public func finalResult(difficulty: Difficulty, durationSeconds: Double) -> GameResult {
        let avgMs = responses.isEmpty ? 0 : responses.reduce(0, +) / Double(responses.count)
        let scored = StroopScorer.score(correct: correct, incorrect: incorrect, avgMs: avgMs)
        let total = correct + incorrect
        let accuracy = total == 0 ? 0 : Double(correct) / Double(total)
        return GameResult(
            gameId: "tap-the-color",
            score: scored.score,
            accuracy: accuracy,
            durationSeconds: durationSeconds,
            difficulty: difficulty,
            rawMetrics: [
                "correct": Double(scored.correct),
                "incorrect": Double(scored.incorrect),
                "avgMs": scored.avgMs
            ]
        )
    }

    private func nextStimulus() {
        let word = allOptions[Int(rng.nextUInt64() % UInt64(allOptions.count))]
        let ink = allOptions[Int(rng.nextUInt64() % UInt64(allOptions.count))]
        currentStimulus = StroopStimulus(word: word, inkColor: ink)
        stimulusStart = Date()
    }
}
