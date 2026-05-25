import Foundation
import SwiftData

@MainActor
public protocol StreakRepository: AnyObject, Sendable {
    func load() throws -> StreakState
    func save(_ state: StreakState) throws
}

@MainActor
public final class SwiftDataStreakRepository: StreakRepository {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func load() throws -> StreakState {
        let descriptor = FetchDescriptor<StreakState>()
        if let existing = try context.fetch(descriptor).first {
            return existing
        }
        let fresh = StreakState()
        context.insert(fresh)
        try context.save()
        return fresh
    }

    public func save(_ state: StreakState) throws {
        try context.save()
    }
}
