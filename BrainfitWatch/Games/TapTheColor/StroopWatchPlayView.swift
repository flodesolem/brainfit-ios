import SwiftUI

struct StroopWatchPlayView: View {
    @State private var viewModel: StroopViewModel
    private let difficulty: Difficulty
    private let onComplete: @MainActor (GameResult) -> Void
    @State private var remainingSeconds: Int
    @State private var timerTask: Task<Void, Never>?

    init(config: StroopConfig,
         difficulty: Difficulty,
         onComplete: @escaping @MainActor (GameResult) -> Void) {
        // Klokkeskjermen er liten — bruk maks 3 fargevalg uansett vanskelighetsgrad
        let watchConfig = StroopConfig(
            totalSeconds: config.totalSeconds,
            optionCount: min(3, config.optionCount)
        )
        self._viewModel = State(initialValue: StroopViewModel(config: watchConfig))
        self.difficulty = difficulty
        self.onComplete = onComplete
        self._remainingSeconds = State(initialValue: watchConfig.totalSeconds)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Spacer()
                Image(systemName: "timer")
                    .font(.caption2)
                Text("\(remainingSeconds)s")
                    .font(.caption.monospacedDigit())
            }

            Spacer(minLength: 2)

            Text(viewModel.currentStimulus.word.displayName)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(viewModel.currentStimulus.inkColor.swiftUIColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .accessibilityLabel("Ord: \(viewModel.currentStimulus.word.displayName), farge: \(viewModel.currentStimulus.inkColor.displayName)")

            Spacer(minLength: 2)

            optionsRow
        }
        .padding(.horizontal, 4)
        .onAppear { startTimer() }
        .onDisappear { timerTask?.cancel() }
    }

    private var optionsRow: some View {
        HStack(spacing: 4) {
            ForEach(viewModel.options, id: \.self) { color in
                Button {
                    viewModel.registerAnswer(color)
                } label: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.swiftUIColor)
                        .frame(height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(color.displayName)
            }
        }
    }

    private func startTimer() {
        timerTask = Task { @MainActor in
            for _ in 0..<viewModel.config.totalSeconds {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                remainingSeconds -= 1
            }
            viewModel.markComplete()
            onComplete(viewModel.finalResult(difficulty: difficulty,
                                             durationSeconds: Double(viewModel.config.totalSeconds)))
        }
    }
}
