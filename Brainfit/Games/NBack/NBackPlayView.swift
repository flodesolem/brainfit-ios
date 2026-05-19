import SwiftUI

struct NBackPlayView: View {
    @State private var viewModel: NBackViewModel
    private let difficulty: Difficulty
    private let onComplete: @MainActor (GameResult) -> Void
    @State private var advanceTask: Task<Void, Never>?
    @State private var showingActiveStimulus = false

    init(config: NBackConfig,
         difficulty: Difficulty,
         onComplete: @escaping @MainActor (GameResult) -> Void) {
        self._viewModel = State(initialValue: NBackViewModel(config: config))
        self.difficulty = difficulty
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 32) {
            Text("Trykk MATCH når posisjonen er lik den fra \(viewModel.config.n) runder siden")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            grid
                .padding()

            Button {
                viewModel.registerMatchTap()
            } label: {
                Text("MATCH")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, minHeight: 60)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .disabled(viewModel.currentStimulus == nil)

            Spacer()
        }
        .padding()
        .onAppear { start() }
        .onDisappear { advanceTask?.cancel() }
    }

    private var grid: some View {
        let cells = viewModel.config.gridSize * viewModel.config.gridSize
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: viewModel.config.gridSize)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<cells, id: \.self) { index in
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorFor(index: index))
                    .aspectRatio(1, contentMode: .fit)
                    .accessibilityLabel("Rute \(index + 1)")
            }
        }
    }

    private func colorFor(index: Int) -> Color {
        if showingActiveStimulus, viewModel.currentStimulus?.position == index {
            return .accentColor
        }
        return Color(.secondarySystemBackground)
    }

    private func start() {
        advanceTask = Task { @MainActor in
            for _ in 0..<viewModel.config.stimuliPerRound {
                viewModel.advanceToNext()
                showingActiveStimulus = true
                try? await Task.sleep(for: .milliseconds(viewModel.config.stimulusDurationMs))
                showingActiveStimulus = false
                try? await Task.sleep(for: .milliseconds(viewModel.config.interStimulusMs))
                if Task.isCancelled { return }
            }
            onComplete(viewModel.finalResult(difficulty: difficulty))
        }
    }
}
