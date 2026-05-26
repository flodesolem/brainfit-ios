import SwiftUI

public struct HomeView: View {
    let engine: DailySessionEngine
    let registry: GameRegistry
    let onStartSession: ([String]) -> Void

    private var todayDone: Bool { engine.didCompleteSessionToday() }

    public var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                header
                streakCard
                Spacer()
                startButton
                Spacer().frame(height: Theme.Spacing.lg)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .navigationTitle("Brainfit")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(greeting)
                .font(Theme.FontStyle.title)
            Text(dateString)
                .font(Theme.FontStyle.caption)
                .foregroundStyle(.brainfitMutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Spacing.lg)
    }

    private var streakCard: some View {
        HStack {
            Image(systemName: "flame.fill")
                .font(.title)
                .foregroundStyle(.orange)
            VStack(alignment: .leading) {
                Text("\(engine.currentStreak()) dager på rad")
                    .font(.headline)
                Text("Lengste: \(engine.longestStreak())")
                    .font(.caption)
                    .foregroundStyle(.brainfitMutedText)
            }
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(.brainfitCard))
    }

    private var startButton: some View {
        Button {
            let ids = engine.todaysGameIds(from: registry, count: 3)
            onStartSession(ids)
        } label: {
            Text(todayDone ? "Dagens trening fullført" : "Start dagens trening")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(.borderedProminent)
        .disabled(todayDone || registry.allGames.isEmpty)
        .accessibilityLabel(todayDone ? "Fullført" : "Start dagens trening")
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<10: return "God morgen"
        case 10..<17: return "Hei"
        case 17..<22: return "God kveld"
        default: return "Hei"
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nb_NO")
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
}
