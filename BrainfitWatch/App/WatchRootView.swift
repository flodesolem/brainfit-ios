import SwiftUI

struct WatchRootView: View {
    let environment: WatchAppEnvironment

    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @State private var showingSession = false

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    var body: some View {
        NavigationStack {
            WatchHomeView(
                engine: environment.engine,
                registry: environment.registry,
                onStartSession: startSession
            )
        }
        .preferredColorScheme(appearanceMode.colorScheme)
        .sheet(isPresented: $showingSession) {
            WatchSessionFlowView(
                registry: environment.registry,
                engine: environment.engine,
                runRepository: environment.runRepository,
                state: environment.sessionState,
                onClose: { showingSession = false }
            )
            .preferredColorScheme(appearanceMode.colorScheme)
        }
    }

    private func startSession(gameIds: [String]) {
        environment.sessionState.start(gameIds: gameIds)
        showingSession = true
    }
}
