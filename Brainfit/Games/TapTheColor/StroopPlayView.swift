import SwiftUI

struct StroopPlayView: View {
    @State private var viewModel: StroopViewModel
    private let difficulty: Difficulty
    private let onComplete: @MainActor (GameResult) -> Void
    @State private var remainingSeconds: Int
    @State private var timerTask: Task<Void, Never>?

    init(config: StroopConfig,
         difficulty: Difficulty,
         onComplete: @escaping @MainActor (GameResult) -> Void) {
        self._viewModel = State(initialValue: StroopViewModel(config: config))
        self.difficulty = difficulty
        self.onComplete = onComplete
        self._remainingSeconds = State(initialValue: config.totalSeconds)
    }

    var body: some View {
        VStack(spacing: 32) {
            HStack {
                Image(systemName: "timer")
                Text("\(remainingSeconds)s")
                    .font(.title2.monospacedDigit())
            }
            .padding(.top)

            Spacer()

            Text(viewModel.currentStimulus.word.displayName)
                .font(.system(size: 80, weight: .bold))
                .foregroundStyle(viewModel.currentStimulus.inkColor.swiftUIColor)
                .accessibilityLabel("Ord: \(viewModel.currentStimulus.word.displayName), farge: \(viewModel.currentStimulus.inkColor.displayName)")

            Text("Trykk fargen ordet er skrevet i")
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
            ForEach(viewModel.options, id: \.self) { color in
                Button {
                    viewModel.registerAnswer(color)
                } label: {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color.swiftUIColor)
                        .frame(height: 80)
                        .overlay(
                            Text(color.displayName)
                                .font(.headline)
                                .foregroundStyle(.white)
                        )
                }
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
