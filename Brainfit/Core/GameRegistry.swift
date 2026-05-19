import Foundation

@MainActor
public final class GameRegistry {
    private var games: [String: AnyGame] = [:]

    public init() {}

    public func register<G: Game>(_ game: G) {
        games[G.metadata.id] = AnyGame(game)
    }

    public func game(forId id: String) -> AnyGame? {
        games[id]
    }

    public var allGames: [AnyGame] {
        Array(games.values).sorted { $0.metadata.displayName < $1.metadata.displayName }
    }

    public func games(in category: GameCategory) -> [AnyGame] {
        allGames.filter { $0.metadata.category == category }
    }
}
