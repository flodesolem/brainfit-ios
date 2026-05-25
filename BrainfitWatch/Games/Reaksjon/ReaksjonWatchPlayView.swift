import SwiftUI

struct ReaksjonWatchPlayView: View {
    @State private var viewModel: ReaksjonViewModel
    private let difficulty: Difficulty
    private let onComplete: @MainActor (GameResult) -> Void
    @State private var roundTask: Task<Void, Never>?

    init(config: ReaksjonConfig,
         difficulty: Difficulty,
         onComplete: @escaping @MainActor (GameResult) -> Void) {
        self._viewModel = State(initialValue: ReaksjonViewModel(config: config))
        self.difficulty = difficulty
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("\(min(viewModel.currentRound + 1, viewModel.config.rounds))/\(viewModel.config.rounds)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(headerText)
                .font(.caption.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Circle()
                .fill(circleColor)
                .frame(maxWidth: 90, maxHeight: 90)
                .accessibilityLabel(accessibilityLabel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap()
        }
        .onAppear { runRound() }
        .onDisappear { roundTask?.cancel() }
    }

    private var headerText: String {
        switch viewModel.phase {
        case .waiting: return "Vent…"
        case .go: return "TAPP!"
        case .tooEarly: return "For tidlig!"
        case .feedback:
            if let ms = viewModel.lastReactionMs {
                return String(format: "%.0f ms", ms)
            }
            return ""
        }
    }

    private var circleColor: Color {
        switch viewModel.phase {
        case .waiting: return .gray.opacity(0.4)
        case .go: return .green
        case .tooEarly: return .red
        case .feedback: return .blue
        }
    }

    private var accessibilityLabel: String {
        switch viewModel.phase {
        case .waiting: return "Grå sirkel — vent"
        case .go: return "Grønn sirkel — tapp nå"
        case .tooEarly: return "Rød sirkel — for tidlig"
        case .feedback: return "Blå sirkel — reaksjonstid registrert"
        }
    }

    private func handleTap() {
        let phaseBefore = viewModel.phase
        viewModel.registerTap()
        if phaseBefore == .waiting || phaseBefore == .go {
            scheduleNext()
        }
    }

    private func runRound() {
        viewModel.startWaiting()
        let delay = viewModel.nextDelay()
        roundTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            if Task.isCancelled { return }
            if viewModel.phase == .waiting {
                viewModel.goNow()
            }
        }
    }

    private func scheduleNext() {
        roundTask?.cancel()
        roundTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.8))
            if Task.isCancelled { return }
            viewModel.advanceRound()
            if viewModel.isComplete {
                onComplete(viewModel.finalResult(difficulty: difficulty))
            } else {
                runRound()
            }
        }
    }
}
