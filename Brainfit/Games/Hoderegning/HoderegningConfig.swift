import Foundation

public enum MathOperator: String, CaseIterable, Sendable {
    case add = "+"
    case subtract = "−"
    case multiply = "×"

    public func apply(_ a: Int, _ b: Int) -> Int {
        switch self {
        case .add: return a + b
        case .subtract: return a - b
        case .multiply: return a * b
        }
    }
}

public struct HoderegningConfig: Sendable {
    public let totalSeconds: Int
    public let minOperand: Int
    public let maxOperand: Int
    public let operators: [MathOperator]
    public let allowNegativeResults: Bool

    public init(totalSeconds: Int,
                minOperand: Int,
                maxOperand: Int,
                operators: [MathOperator],
                allowNegativeResults: Bool) {
        self.totalSeconds = totalSeconds
        self.minOperand = minOperand
        self.maxOperand = maxOperand
        self.operators = operators
        self.allowNegativeResults = allowNegativeResults
    }

    public static func forDifficulty(_ difficulty: Difficulty) -> HoderegningConfig {
        switch difficulty {
        case .easy:
            return HoderegningConfig(totalSeconds: 60,
                                     minOperand: 1,
                                     maxOperand: 10,
                                     operators: [.add, .subtract],
                                     allowNegativeResults: false)
        case .medium:
            return HoderegningConfig(totalSeconds: 60,
                                     minOperand: 1,
                                     maxOperand: 20,
                                     operators: [.add, .subtract, .multiply],
                                     allowNegativeResults: false)
        case .hard:
            return HoderegningConfig(totalSeconds: 60,
                                     minOperand: 1,
                                     maxOperand: 50,
                                     operators: [.add, .subtract, .multiply],
                                     allowNegativeResults: true)
        }
    }
}
