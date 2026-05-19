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
        // CloudKit-sync er midlertidig deaktivert mens vi kjører på Personal Team
        // (gratis Apple ID). Re-aktiver ved å bytte tilbake til .private(...)-config
        // når Apple Developer Program er på plass.
        let config: ModelConfiguration
        if inMemory {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }
        return try ModelContainer(for: schema, configurations: [config])
    }
}
