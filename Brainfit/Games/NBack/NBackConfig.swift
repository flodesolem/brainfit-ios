import Foundation

public struct NBackConfig: Sendable {
    public let n: Int                  // 1, 2 eller 3
    public let stimuliPerRound: Int    // 20 i MVP
    public let stimulusDurationMs: Int // 500
    public let interStimulusMs: Int    // 2000
    public let gridSize: Int           // 3 (3x3)

    public init(n: Int,
                stimuliPerRound: Int,
                stimulusDurationMs: Int,
                interStimulusMs: Int,
                gridSize: Int) {
        self.n = n
        self.stimuliPerRound = stimuliPerRound
        self.stimulusDurationMs = stimulusDurationMs
        self.interStimulusMs = interStimulusMs
        self.gridSize = gridSize
    }

    public static func forDifficulty(_ difficulty: Difficulty) -> NBackConfig {
        switch difficulty {
        case .easy:   return NBackConfig(n: 1, stimuliPerRound: 20, stimulusDurationMs: 500, interStimulusMs: 2000, gridSize: 3)
        case .medium: return NBackConfig(n: 2, stimuliPerRound: 20, stimulusDurationMs: 500, interStimulusMs: 2000, gridSize: 3)
        case .hard:   return NBackConfig(n: 3, stimuliPerRound: 20, stimulusDurationMs: 500, interStimulusMs: 2000, gridSize: 3)
        }
    }
}
