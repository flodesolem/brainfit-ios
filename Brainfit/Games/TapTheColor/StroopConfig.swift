import SwiftUI

public enum StroopColor: String, CaseIterable, Sendable {
    case red, green, blue, yellow, purple

    public var displayName: String {
        switch self {
        case .red: return "RØD"
        case .green: return "GRØNN"
        case .blue: return "BLÅ"
        case .yellow: return "GUL"
        case .purple: return "LILLA"
        }
    }

    public var swiftUIColor: Color {
        switch self {
        case .red: return .red
        case .green: return .green
        case .blue: return .blue
        case .yellow: return .yellow
        case .purple: return .purple
        }
    }
}

public struct StroopConfig: Sendable {
    public let totalSeconds: Int
    public let optionCount: Int

    public init(totalSeconds: Int, optionCount: Int) {
        self.totalSeconds = totalSeconds
        self.optionCount = optionCount
    }

    public static func forDifficulty(_ difficulty: Difficulty) -> StroopConfig {
        switch difficulty {
        case .easy:   return StroopConfig(totalSeconds: 30, optionCount: 3)
        case .medium: return StroopConfig(totalSeconds: 30, optionCount: 4)
        case .hard:   return StroopConfig(totalSeconds: 30, optionCount: 5)
        }
    }
}
