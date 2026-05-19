import SwiftUI

public struct NBackWatchGame: Game {
    public init() {}

    public static let metadata = GameMetadata(
        id: "nback",
        displayName: "Husk Mønsteret",
        category: .memory,
        shortDescription: "Trykk når lik forrige",
        icon: "square.grid.3x3.fill",
        targetDurationSeconds: 50
    )

    @MainActor
    public func makeIntroView() -> some View {
        NBackWatchIntroView()
    }

    @MainActor
    public func makePlayView(difficulty: Difficulty,
                             onComplete: @escaping @MainActor (GameResult) -> Void) -> some View {
        NBackWatchPlayView(
            config: .forDifficulty(difficulty),
            difficulty: difficulty,
            onComplete: onComplete
        )
    }
}

struct NBackWatchIntroView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "square.grid.3x3.fill")
                .font(.title)
                .foregroundStyle(Color.accentColor)
            Text("Husk Mønsteret")
                .font(.headline)
            Text("Trykk MATCH når posisjonen er lik forrige.")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }
}
