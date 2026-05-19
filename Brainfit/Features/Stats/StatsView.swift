import SwiftUI
import Charts

public struct StatsView: View {
    let runRepository: any GameRunRepository
    let registry: GameRegistry

    @State private var selectedRange: Range = .month
    @State private var runs: [GameRun] = []

    public enum Range: String, CaseIterable, Identifiable {
        case week, month, quarter
        public var id: String { rawValue }
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
        var label: String {
            switch self {
            case .week: return "7 dager"
            case .month: return "30 dager"
            case .quarter: return "90 dager"
            }
        }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Picker("Tidsrom", selection: $selectedRange) {
                        ForEach(Range.allCases) { range in
                            Text(range.label).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)

                    chartSection

                    gameCards
                }
                .padding()
            }
            .navigationTitle("Statistikk")
            .task(id: selectedRange) { await reload() }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Snittscore per dag")
                .font(.headline)
            if runs.isEmpty {
                Text("Ingen data ennå — spill noen økter først.")
                    .font(.subheadline)
                    .foregroundStyle(.brainfitMutedText)
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                Chart(dailyAverages(), id: \.day) { entry in
                    LineMark(x: .value("Dag", entry.day), y: .value("Score", entry.average))
                    PointMark(x: .value("Dag", entry.day), y: .value("Score", entry.average))
                }
                .frame(height: 200)
            }
        }
    }

    private var gameCards: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Per spill")
                .font(.headline)
            ForEach(registry.allGames, id: \.metadata.id) { game in
                let filtered = runs.filter { $0.gameId == game.metadata.id }
                gameCard(metadata: game.metadata, runs: filtered)
            }
        }
    }

    private func gameCard(metadata: GameMetadata, runs: [GameRun]) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: metadata.icon)
                .font(.title2)
                .frame(width: 40)
            VStack(alignment: .leading) {
                Text(metadata.displayName).font(.headline)
                Text(runs.isEmpty
                     ? "Ingen økter enda"
                     : "Beste: \(runs.map(\.score).max() ?? 0) · \(runs.count) økter")
                    .font(.caption)
                    .foregroundStyle(.brainfitMutedText)
            }
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(.brainfitCard))
    }

    private func dailyAverages() -> [(day: Date, average: Double)] {
        let grouped = Dictionary(grouping: runs) { Calendar.current.startOfDay(for: $0.playedAt) }
        return grouped
            .map { (day: $0.key, average: Double($0.value.reduce(0) { $0 + $1.score }) / Double($0.value.count)) }
            .sorted { $0.day < $1.day }
    }

    @MainActor
    private func reload() async {
        let since = Calendar.current.date(byAdding: .day, value: -selectedRange.days, to: Date()) ?? Date()
        runs = (try? runRepository.all(since: since)) ?? []
    }
}
