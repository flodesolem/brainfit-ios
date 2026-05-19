import SwiftUI

struct WatchSessionFlowView: View {
    let registry: GameRegistry
    let engine: DailySessionEngine
    let runRepository: any GameRunRepository
    @Bindable var state: SessionState
    let onClose: () -> Void

    @State private var showingCancelConfirm = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content
            cancelButton
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state.phase {
        case .idle:
            ProgressView()
        case .intro(let gameId):
            introView(for: gameId)
        case .playing(let gameId, let difficulty):
            playView(for: gameId, difficulty: difficulty)
        case .result(let result):
            resultView(for: result)
        case .summary(let total):
            summaryView(total: total)
        case .cancelled:
            ProgressView()
                .onAppear { onClose() }
        }
    }

    private var cancelButton: some View {
        Button {
            showingCancelConfirm = true
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .padding(4)
        .accessibilityLabel("Avbryt økt")
        .confirmationDialog("Avbryt økten?", isPresented: $showingCancelConfirm) {
            Button("Avbryt", role: .destructive) {
                state.cancel()
            }
            Button("Fortsett", role: .cancel) {}
        }
    }

    private func introView(for gameId: String) -> some View {
        ScrollView {
            VStack(spacing: 8) {
                if let game = registry.game(forId: gameId) {
                    game.makeIntroView()
                } else {
                    Text("Ukjent spill: \(gameId)")
                        .font(.caption)
                }
                Button("Start") {
                    let difficulty = (try? engine.recommendedDifficulty(forGameId: gameId)) ?? .medium
                    state.startPlay(difficulty: difficulty)
                }
                .buttonStyle(.borderedProminent)
                .font(.callout.bold())
            }
            .padding(.vertical, 4)
        }
    }

    private func playView(for gameId: String, difficulty: Difficulty) -> some View {
        Group {
            if let game = registry.game(forId: gameId) {
                game.makePlayView(difficulty: difficulty) { result in
                    persist(result: result)
                    state.recordResult(result)
                }
            } else {
                Text("Ukjent spill: \(gameId)")
            }
        }
    }

    private func resultView(for result: GameResult) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.title2)
                .foregroundStyle(.yellow)
            Text("Score")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(result.score)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
            Button("Neste") {
                state.advance()
            }
            .buttonStyle(.borderedProminent)
            .font(.callout)
        }
        .padding(8)
    }

    private func summaryView(total: Int) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title)
                .foregroundStyle(.green)
            Text("Fullført")
                .font(.headline)
            Text("Total: \(total)")
                .font(.caption)
            Button("Ferdig") {
                try? engine.recordCompletion(score: total)
                onClose()
            }
            .buttonStyle(.borderedProminent)
            .font(.callout)
        }
        .padding(8)
    }

    private func persist(result: GameResult) {
        do {
            let run = try GameRun(from: result, sessionId: state.sessionId)
            try runRepository.save(run)
        } catch {
            // Stille feil — en feilet save bryter ikke økten
        }
    }
}
