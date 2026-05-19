import SwiftUI

@main
struct BrainfitApp: App {
    @State private var environment: AppEnvironment?
    @State private var initError: String?

    private static var isRunningTests: Bool {
        NSClassFromString("XCTestCase") != nil
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let environment {
                    Text("Core OK · Spill registrert: \(environment.registry.allGames.count)")
                        .font(.headline)
                } else if let initError {
                    Text("Init feilet: \(initError)")
                        .foregroundStyle(.red)
                } else {
                    ProgressView()
                }
            }
            .task {
                guard !Self.isRunningTests else { return }
                do {
                    environment = try AppEnvironment()
                } catch {
                    initError = error.localizedDescription
                }
            }
        }
    }
}
