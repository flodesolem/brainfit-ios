import SwiftUI

struct WatchHomeView: View {
    let engine: DailySessionEngine
    let registry: GameRegistry
    let onStartSession: ([String]) -> Void

    @State private var streak: Int = 0
    @State private var didToday: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            Text("Brainfit")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
                Text("\(streak)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
            }

            Text(didToday ? "Fullført i dag" : "Dagens trening")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer(minLength: 4)

            Button {
                let ids = engine.todaysGameIds(from: registry, count: 3)
                onStartSession(ids)
            } label: {
                Text(didToday ? "Tren igjen" : "Start")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .disabled(registry.allGames.isEmpty)
        }
        .padding(.horizontal, 4)
        .onAppear { refresh() }
    }

    private func refresh() {
        streak = engine.currentStreak()
        didToday = engine.didCompleteSessionToday()
    }
}
