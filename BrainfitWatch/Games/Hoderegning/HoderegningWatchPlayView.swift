import SwiftUI

struct HoderegningWatchPlayView: View {
    @State private var viewModel: HoderegningViewModel
    private let difficulty: Difficulty
    private let onComplete: @MainActor (GameResult) -> Void
    @State private var remainingSeconds: Int
    @State private var timerTask: Task<Void, Never>?

    init(config: HoderegningConfig,
         difficulty: Difficulty,
         onComplete: @escaping @MainActor (GameResult) -> Void) {
        self._viewModel = State(initialValue: HoderegningViewModel(config: config))
        self.difficulty = difficulty
        self.onComplete = onComplete
        self._remainingSeconds = State(initialValue: config.totalSeconds)
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

            Text(viewModel.currentStimulus.displayExpression)
                .font(.system(size: 30, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .accessibilityLabel("Regnestykke: \(viewModel.currentStimulus.displayExpression)")

            Spacer(minLength: 2)

            grid
        }
        .padding(.horizontal, 4)
        .onAppear { startTimer() }
        .onDisappear { timerTask?.cancel() }
    }

    private var grid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 2)
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(viewModel.currentStimulus.options, id: \.self) { option in
                Button {
                    viewModel.registerAnswer(option)
                } label: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.25))
                        .frame(height: 36)
                        .overlay(
                            Text("\(option)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Svar \(option)")
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
