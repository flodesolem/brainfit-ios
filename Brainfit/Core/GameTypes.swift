import Foundation

public enum Difficulty: Int, Codable, CaseIterable, Sendable {
    case easy = 1
    case medium = 2
    case hard = 3

    public func bumped(by delta: Int) -> Difficulty {
        let raw = max(Difficulty.easy.rawValue, min(Difficulty.hard.rawValue, rawValue + delta))
        return Difficulty(rawValue: raw) ?? self
    }
}

public enum GameCategory: String, Codable, CaseIterable, Sendable {
    case memory
    case reaction
    case attention
    case language
    case math
    case problemSolving
}

public struct GameMetadata: Sendable, Hashable {
    public let id: String
    public let displayName: String
    public let category: GameCategory
    public let shortDescription: String
    public let icon: String
    public let targetDurationSeconds: Int

    public init(id: String,
                displayName: String,
                category: GameCategory,
                shortDescription: String,
                icon: String,
                targetDurationSeconds: Int) {
        self.id = id
        self.displayName = displayName
        self.category = category
        self.shortDescription = shortDescription
        self.icon = icon
        self.targetDurationSeconds = targetDurationSeconds
    }
}
