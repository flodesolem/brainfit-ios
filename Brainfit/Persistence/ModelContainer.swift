import Foundation
import SwiftData

public enum BrainfitModelContainer {
    public static let allModels: [any PersistentModel.Type] = [
        GameRun.self,
        DailySessionRecord.self,
        StreakState.self
    ]

    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(allModels)
        let config: ModelConfiguration
        if inMemory {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.com.frodesolem.brainfit")
            )
        }
        return try ModelContainer(for: schema, configurations: [config])
    }
}
