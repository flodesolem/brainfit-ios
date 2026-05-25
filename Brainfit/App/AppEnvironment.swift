import Foundation
import SwiftData

@MainActor
public final class AppEnvironment {
    public let modelContainer: ModelContainer
    public let runRepository: any GameRunRepository
    public let streakRepository: any StreakRepository
    public let engine: DailySessionEngine
    public let registry: GameRegistry
    public let sessionState: SessionState

    public init(inMemory: Bool = false) throws {
        let container = try BrainfitModelContainer.makeContainer(inMemory: inMemory)
        self.modelContainer = container
        let context = ModelContext(container)
        let runs = SwiftDataGameRunRepository(context: context)
        let streaks = SwiftDataStreakRepository(context: context)
        self.runRepository = runs
        self.streakRepository = streaks
        self.engine = DailySessionEngine(runs: runs, streaks: streaks)
        self.registry = GameRegistry()
        self.sessionState = SessionState()
        self.registry.register(NBackGame())
        self.registry.register(TapTheColorGame())
        self.registry.register(HoderegningGame())
        self.registry.register(ReaksjonGame())
    }
}
