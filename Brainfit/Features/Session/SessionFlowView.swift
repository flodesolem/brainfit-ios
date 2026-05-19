import SwiftUI

public struct SessionFlowView: View {
    let registry: GameRegistry
    let engine: DailySessionEngine
    let runRepository: any GameRunRepository
    @Bindable var state: SessionState
    let onClose: () -> Void

    @State private var showingCancelConfirm = false

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            content
            cancelButton
        }
        .background(Color.brainfitBackground.ignoresSafeArea())
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
            VStack { ProgressView() }
                .onAppear { onClose() }
        }
    }

    private var cancelButton: some View {
        Button {
            showingCancelConfirm = true
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .accessibilityLabel("Avbryt økt")
        .confirmationDialog("Avbryt økten?", isPresented: $showingCancelConfirm) {
            Button("Avbryt økten", role: .destructive) {
                state.cancel()
            }
            Button("Fortsett", role: .cancel) {}
        } message: {
            Text("Resultater fra denne økten vil ikke lagres.")
        }
    }

    private func introView(for gameId: String) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            if let game = registry.game(forId: gameId) {
                game.makeIntroView()
            } else {
                Text("Ukjent spill: \(gameId)")
            }
            Button("Start") {
                let difficulty = (try? engine.recommendedDifficulty(forGameId: gameId)) ?? .medium
                state.startPlay(difficulty: difficulty)
            }
            .buttonStyle(.borderedProminent)
            .font(.title3.bold())
        }
        .padding()
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
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)
            Text("Score")
                .font(.headline)
            Text("\(result.score)")
                .font(Theme.FontStyle.displayLarge)
            Button("Neste") {
                state.advance()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func summaryView(total: Int) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            Text("Økten er fullført")
                .font(.title2.bold())
            Text("Totalscore: \(total)")
                .font(.title3)
            Button("Ferdig") {
                try? engine.recordCompletion(score: total)
                onClose()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
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
