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
        if inMemory {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [config])
        }
        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.frodesolem.brainfit")
        )
        do {
            return try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            // Fall back til lokal-only når CloudKit-entitlements ikke er
            // tilgjengelig (typisk i simulator-tester med CODE_SIGNING_ALLOWED=NO).
            let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [localConfig])
        }
    }
}
