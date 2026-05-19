import Foundation
import Observation

public enum SessionPhase: Equatable {
    case idle
    case intro(gameId: String)
    case playing(gameId: String, difficulty: Difficulty)
    case result(GameResult)
    case summary(totalScore: Int)
    case cancelled
}

@Observable
@MainActor
public final class SessionState {
    public private(set) var phase: SessionPhase = .idle
    public private(set) var queuedGameIds: [String] = []
    public private(set) var currentIndex: Int = 0
    public private(set) var completedResults: [GameResult] = []
    public private(set) var sessionId: UUID = UUID()

    public init() {}

    public func start(gameIds: [String]) {
        sessionId = UUID()
        queuedGameIds = gameIds
        currentIndex = 0
        completedResults = []
        guard let first = gameIds.first else {
            phase = .idle
            return
        }
        phase = .intro(gameId: first)
    }

    public func startPlay(difficulty: Difficulty) {
        guard case .intro(let gameId) = phase else { return }
        phase = .playing(gameId: gameId, difficulty: difficulty)
    }

    public func recordResult(_ result: GameResult) {
        completedResults.append(result)
        phase = .result(result)
    }

    public func advance() {
        currentIndex += 1
        if currentIndex >= queuedGameIds.count {
            let total = completedResults.reduce(0) { $0 + $1.score }
            phase = .summary(totalScore: total)
        } else {
            phase = .intro(gameId: queuedGameIds[currentIndex])
        }
    }

    public func cancel() {
        phase = .cancelled
    }

    public func reset() {
        phase = .idle
        queuedGameIds = []
        currentIndex = 0
        completedResults = []
    }
}
