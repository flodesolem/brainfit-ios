import Foundation
import SwiftData

public protocol GameRunRepository: AnyObject, Sendable {
    func save(_ run: GameRun) throws
    func recent(forGameId gameId: String, limit: Int) throws -> [GameRun]
    func all(since date: Date) throws -> [GameRun]
}

@MainActor
public final class SwiftDataGameRunRepository: GameRunRepository {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func save(_ run: GameRun) throws {
        context.insert(run)
        try context.save()
    }

    public func recent(forGameId gameId: String, limit: Int) throws -> [GameRun] {
        var descriptor = FetchDescriptor<GameRun>(
            predicate: #Predicate { $0.gameId == gameId },
            sortBy: [SortDescriptor(\.playedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    public func all(since date: Date) throws -> [GameRun] {
        let descriptor = FetchDescriptor<GameRun>(
            predicate: #Predicate { $0.playedAt >= date },
            sortBy: [SortDescriptor(\.playedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
}
