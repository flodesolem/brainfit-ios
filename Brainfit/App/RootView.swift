import SwiftUI

struct RootView: View {
    let environment: AppEnvironment

    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @State private var showingSession = false

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    var body: some View {
        TabView {
            HomeView(
                engine: environment.engine,
                registry: environment.registry,
                onStartSession: startSession
            )
            .tabItem { Label("Hjem", systemImage: "house.fill") }

            StatsView(
                runRepository: environment.runRepository,
                registry: environment.registry
            )
            .tabItem { Label("Statistikk", systemImage: "chart.line.uptrend.xyaxis") }

            SettingsView()
                .tabItem { Label("Innstillinger", systemImage: "gearshape.fill") }
        }
        .preferredColorScheme(appearanceMode.colorScheme)
        .fullScreenCover(isPresented: $showingSession) {
            SessionFlowView(
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
