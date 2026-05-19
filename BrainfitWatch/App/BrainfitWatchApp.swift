import SwiftUI

@main
struct BrainfitWatchApp: App {
    @State private var environment: WatchAppEnvironment?
    @State private var initError: String?

    var body: some Scene {
        WindowGroup {
            Group {
                if let environment {
                    WatchRootView(environment: environment)
                } else if let initError {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
                        Text("Klarte ikke å starte")
                            .font(.caption)
                        Text(initError)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(8)
                } else {
                    ProgressView()
                }
            }
            .task {
                do {
                    environment = try WatchAppEnvironment()
                } catch {
                    initError = error.localizedDescription
                }
            }
        }
    }
}
