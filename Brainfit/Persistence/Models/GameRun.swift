import Foundation
import SwiftData

@Model
public final class GameRun {
    public var id: UUID = UUID()
    public var gameId: String = ""
    public var playedAt: Date = Date()
    public var score: Int = 0
    public var accuracy: Double = 0
    public var durationSeconds: Double = 0
    public var difficulty: Int = 2
    public var rawMetricsJSON: String = "{}"
    public var sessionId: UUID?

    public init(gameId: String,
                score: Int,
                accuracy: Double,
                durationSeconds: Double,
                difficulty: Difficulty,
                rawMetricsJSON: String,
                sessionId: UUID? = nil,
                playedAt: Date = Date()) {
        self.id = UUID()
        self.gameId = gameId
        self.score = score
        self.accuracy = accuracy
        self.durationSeconds = durationSeconds
        self.difficulty = difficulty.rawValue
        self.rawMetricsJSON = rawMetricsJSON
        self.sessionId = sessionId
        self.playedAt = playedAt
    }

    public var difficultyEnum: Difficulty {
        Difficulty(rawValue: difficulty) ?? .medium
    }
}

public extension GameRun {
    convenience init(from result: GameResult, sessionId: UUID? = nil, playedAt: Date = Date()) throws {
        self.init(
            gameId: result.gameId,
            score: result.score,
            accuracy: result.accuracy,
            durationSeconds: result.durationSeconds,
            difficulty: result.difficulty,
            rawMetricsJSON: try result.rawMetricsJSON(),
            sessionId: sessionId,
            playedAt: playedAt
        )
    }
}
