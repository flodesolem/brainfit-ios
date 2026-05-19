import SwiftUI

struct RootView: View {
    let environment: AppEnvironment

    @State private var showingSession = false

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
        .fullScreenCover(isPresented: $showingSession) {
            SessionFlowView(
                registry: environment.registry,
                engine: environment.engine,
                runRepository: environment.runRepository,
                state: environment.sessionState,
                onClose: { showingSession = false }
            )
        }
    }

    private func startSession(gameIds: [String]) {
        environment.sessionState.start(gameIds: gameIds)
        showingSession = true
    }
}
