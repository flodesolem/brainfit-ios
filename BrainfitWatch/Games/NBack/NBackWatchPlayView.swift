import SwiftUI

struct NBackWatchPlayView: View {
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
        VStack(spacing: 6) {
            Text("N=\(viewModel.config.n)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            grid
                .frame(maxWidth: 140, maxHeight: 140)

            Button {
                viewModel.registerMatchTap()
            } label: {
                Text("MATCH")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .disabled(viewModel.currentStimulus == nil)
        }
        .padding(.horizontal, 4)
        .onAppear { start() }
        .onDisappear { advanceTask?.cancel() }
    }

    private var grid: some View {
        let cells = viewModel.config.gridSize * viewModel.config.gridSize
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: viewModel.config.gridSize)
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(0..<cells, id: \.self) { index in
                RoundedRectangle(cornerRadius: 6)
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
        return Color.gray.opacity(0.3)
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
