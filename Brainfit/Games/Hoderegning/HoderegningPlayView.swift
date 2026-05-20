import SwiftUI

struct HoderegningPlayView: View {
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
        VStack(spacing: 24) {
            HStack {
                Image(systemName: "timer")
                Text("\(remainingSeconds)s")
                    .font(.title2.monospacedDigit())
                Spacer()
                Text("Riktig: \(viewModel.correct)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.top)

            Spacer()

            Text(viewModel.currentStimulus.displayExpression)
                .font(.system(size: 60, weight: .bold))
                .monospacedDigit()
                .accessibilityLabel("Regnestykke: \(viewModel.currentStimulus.displayExpression)")

            Text("Velg riktig svar")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            grid

            Spacer().frame(height: 24)
        }
        .padding()
        .onAppear { startTimer() }
        .onDisappear { timerTask?.cancel() }
    }

    private var grid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(viewModel.currentStimulus.options, id: \.self) { option in
                Button {
                    viewModel.registerAnswer(option)
                } label: {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(height: 80)
                        .overlay(
                            Text("\(option)")
                                .font(.title.bold().monospacedDigit())
                                .foregroundStyle(.primary)
                        )
                }
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
