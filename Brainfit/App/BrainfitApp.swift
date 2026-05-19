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
            if Self.isRunningTests {
                // Placeholder under tester — unngå å initialisere AppEnvironment
                Text("Tests")
            } else {
                Group {
                    if let environment {
                        RootView(environment: environment)
                    } else if let initError {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.orange)
                            Text("Klarte ikke å starte appen")
                                .font(.headline)
                            Text(initError)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    } else {
                        ProgressView()
                    }
                }
                .task {
                    do {
                        environment = try AppEnvironment()
                    } catch {
                        initError = error.localizedDescription
                    }
                }
            }
        }
    }
}
