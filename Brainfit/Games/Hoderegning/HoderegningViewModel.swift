import Foundation
import Observation

public struct MathStimulus: Identifiable, Sendable, Equatable {
    public let id = UUID()
    public let operandA: Int
    public let op: MathOperator
    public let operandB: Int
    public let correctAnswer: Int
    public let options: [Int]

    public var displayExpression: String {
        "\(operandA) \(op.rawValue) \(operandB)"
    }

    public static func == (lhs: MathStimulus, rhs: MathStimulus) -> Bool {
        lhs.id == rhs.id
    }
}

@Observable
@MainActor
public final class HoderegningViewModel {
    public let config: HoderegningConfig
    public private(set) var currentStimulus: MathStimulus
    public private(set) var correct: Int = 0
    public private(set) var incorrect: Int = 0
    public private(set) var currentStreak: Int = 0
    public private(set) var bestStreak: Int = 0
    public private(set) var responses: [Double] = []
    public private(set) var isComplete: Bool = false
    private var stimulusStart: Date

    private var rng: SystemRandomNumberGeneratorBox

    public init(config: HoderegningConfig, seed: UInt64? = nil) {
        self.config = config
        var prng = SystemRandomNumberGeneratorBox(seed: seed)
        self.currentStimulus = Self.makeStimulus(config: config, rng: &prng)
        self.rng = prng
        self.stimulusStart = Date()
    }

    public func registerAnswer(_ chosen: Int) {
        let ms = Date().timeIntervalSince(stimulusStart) * 1000
        responses.append(ms)
        if chosen == currentStimulus.correctAnswer {
            correct += 1
            currentStreak += 1
            if currentStreak > bestStreak {
                bestStreak = currentStreak
            }
        } else {
            incorrect += 1
            currentStreak = 0
        }
        nextStimulus()
    }

    public func markComplete() {
        isComplete = true
    }

    public func finalResult(difficulty: Difficulty, durationSeconds: Double) -> GameResult {
        let avgMs = responses.isEmpty ? 0 : responses.reduce(0, +) / Double(responses.count)
        let scored = HoderegningScorer.score(correct: correct,
                                             incorrect: incorrect,
                                             avgMs: avgMs,
                                             bestStreak: bestStreak)
        let total = correct + incorrect
        let accuracy = total == 0 ? 0 : Double(correct) / Double(total)
        return GameResult(
            gameId: "hoderegning",
            score: scored.score,
            accuracy: accuracy,
            durationSeconds: durationSeconds,
            difficulty: difficulty,
            rawMetrics: [
                "correct": Double(scored.correct),
                "incorrect": Double(scored.incorrect),
                "avgMs": scored.avgMs,
                "streak": Double(scored.bestStreak)
            ]
        )
    }

    private func nextStimulus() {
        currentStimulus = Self.makeStimulus(config: config, rng: &rng)
        stimulusStart = Date()
    }

    // MARK: - Stimulus generation

    private static func makeStimulus(config: HoderegningConfig,
                                     rng: inout SystemRandomNumberGeneratorBox) -> MathStimulus {
        let opCount = UInt64(config.operators.count)
        let op = config.operators[Int(rng.nextUInt64() % opCount)]

        // Cap multiplication operands to keep answers reasonable.
        let effectiveMax: Int
        switch op {
        case .multiply:
            effectiveMax = min(config.maxOperand, 12)
        default:
            effectiveMax = config.maxOperand
        }
        let minOp = config.minOperand
        let range = UInt64(max(1, effectiveMax - minOp + 1))

        var a = minOp + Int(rng.nextUInt64() % range)
        var b = minOp + Int(rng.nextUInt64() % range)

        // Avoid negative subtraction results when not allowed.
        if op == .subtract, !config.allowNegativeResults, a < b {
            swap(&a, &b)
        }

        let answer = op.apply(a, b)

        let options = makeOptions(correctAnswer: answer,
                                  operandA: a,
                                  operandB: b,
                                  op: op,
                                  config: config,
                                  rng: &rng)

        return MathStimulus(operandA: a,
                            op: op,
                            operandB: b,
                            correctAnswer: answer,
                            options: options)
    }

    private static func makeOptions(correctAnswer: Int,
                                    operandA: Int,
                                    operandB: Int,
                                    op: MathOperator,
                                    config: HoderegningConfig,
                                    rng: inout SystemRandomNumberGeneratorBox) -> [Int] {
        var pool: [Int] = [correctAnswer]

        // Candidate distractors — closest first, then wider.
        var candidates: [Int] = [
            correctAnswer + 1,
            correctAnswer - 1,
            correctAnswer + 2,
            correctAnswer - 2,
            correctAnswer + 5,
            correctAnswer - 5,
            correctAnswer + operandA,
            correctAnswer - operandA,
            correctAnswer + operandB,
            correctAnswer - operandB,
            op.apply(operandA, operandB + 1),
            op.apply(operandA + 1, operandB),
            op.apply(operandB, operandA)  // swapped — often same, but harmless dup
        ]
        if config.allowNegativeResults {
            candidates.append(-correctAnswer)
        } else {
            candidates = candidates.filter { $0 >= 0 }
        }

        // Shuffle candidate order deterministically via seeded RNG.
        for i in stride(from: candidates.count - 1, through: 1, by: -1) {
            let j = Int(rng.nextUInt64() % UInt64(i + 1))
            candidates.swapAt(i, j)
        }

        for candidate in candidates where pool.count < 4 {
            if candidate != correctAnswer, !pool.contains(candidate) {
                pool.append(candidate)
            }
        }

        // Fallback: fill with sequential numbers if we somehow ran out.
        var fallback = correctAnswer + 10
        while pool.count < 4 {
            if !pool.contains(fallback) {
                pool.append(fallback)
            }
            fallback += 1
        }

        // Shuffle final options.
        for i in stride(from: pool.count - 1, through: 1, by: -1) {
            let j = Int(rng.nextUInt64() % UInt64(i + 1))
            pool.swapAt(i, j)
        }
        return pool
    }
}
