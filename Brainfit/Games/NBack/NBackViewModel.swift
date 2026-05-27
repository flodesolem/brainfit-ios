import Foundation
import Observation

public struct NBackStimulus: Identifiable, Sendable {
    public let id = UUID()
    public let position: Int       // 0..<(gridSize*gridSize)
    public let isTarget: Bool

    public init(position: Int, isTarget: Bool) {
        self.position = position
        self.isTarget = isTarget
    }
}

@Observable
@MainActor
public final class NBackViewModel {
    public let config: NBackConfig
    public private(set) var stimuli: [NBackStimulus] = []
    public private(set) var currentIndex: Int = -1
    public private(set) var hits: Int = 0
    public private(set) var falseAlarms: Int = 0
    public private(set) var responses: [Double] = [] // reaksjonstider i ms
    public private(set) var stimulusStart: Date?
    public private(set) var isComplete: Bool = false

    private var rng: SystemRandomNumberGeneratorBox

    public init(config: NBackConfig, seed: UInt64? = nil) {
        self.config = config
        self.rng = SystemRandomNumberGeneratorBox(seed: seed)
        generateStimuli()
    }

    public var currentStimulus: NBackStimulus? {
        guard currentIndex >= 0, currentIndex < stimuli.count else { return nil }
        return stimuli[currentIndex]
    }

    public func advanceToNext() {
        currentIndex += 1
        stimulusStart = Date()
        if currentIndex >= stimuli.count {
            isComplete = true
        }
    }

    public func registerMatchTap() {
        guard let stimulus = currentStimulus else { return }
        if let start = stimulusStart {
            responses.append(Date().timeIntervalSince(start) * 1000)
        }
        if stimulus.isTarget {
            hits += 1
        } else {
            falseAlarms += 1
        }
    }

    public func finalResult(difficulty: Difficulty) -> GameResult {
        let targets = stimuli.filter(\.isTarget).count
        let nonTargets = stimuli.count - targets
        let avgMs = responses.isEmpty ? 0 : responses.reduce(0, +) / Double(responses.count)
        let scored = NBackScorer.score(
            targets: targets,
            nonTargets: nonTargets,
            hits: hits,
            falseAlarms: falseAlarms,
            avgReactionMs: avgMs
        )
        return GameResult(
            gameId: "nback",
            score: scored.score,
            accuracy: targets > 0 ? Double(hits) / Double(targets) : 1.0,
            durationSeconds: Double(config.stimuliPerRound) * Double(config.stimulusDurationMs + config.interStimulusMs) / 1000,
            difficulty: difficulty,
            rawMetrics: [
                "hits": Double(scored.hits),
                "misses": Double(scored.misses),
                "falseAlarms": Double(scored.falseAlarms),
                "correctRejections": Double(scored.correctRejections),
                "avgReactionMs": scored.avgReactionMs
            ]
        )
    }

    private func generateStimuli() {
        let gridCells = config.gridSize * config.gridSize
        var positions: [Int] = []
        for _ in 0..<config.stimuliPerRound {
            positions.append(Int(rng.nextUInt64() % UInt64(gridCells)))
        }
        // ~30 % targets: tving noen til match. Sortert iterasjon for determinisme
        // (Set-iterasjon i Swift har ikke-deterministisk rekkefølge per prosess).
        let targetIndices = Array(config.n..<positions.count)
            .shuffled(using: &rng)
            .prefix(config.stimuliPerRound / 3)
            .sorted()
        for index in targetIndices where index >= config.n {
            positions[index] = positions[index - config.n]
        }
        stimuli = positions.enumerated().map { idx, pos in
            let isTarget = idx >= config.n && pos == positions[idx - config.n]
            return NBackStimulus(position: pos, isTarget: isTarget)
        }
    }
}

// Determinisme: SeedableRNG-wrapper for tester
public struct SystemRandomNumberGeneratorBox: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64?) {
        self.state = seed ?? UInt64.random(in: .min ... .max)
    }

    public mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }

    public mutating func nextUInt64() -> UInt64 { next() }
}
