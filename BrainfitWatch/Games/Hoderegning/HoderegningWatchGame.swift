import SwiftUI

public struct HoderegningWatchGame: Game {
    public init() {}

    public static let metadata = GameMetadata(
        id: "hoderegning",
        displayName: "Hoderegning",
        category: .math,
        shortDescription: "Regn raskt — flest riktige på et minutt",
        icon: "plus.forwardslash.minus",
        targetDurationSeconds: 60
    )

    @MainActor
    public func makeIntroView() -> some View {
        HoderegningWatchIntroView()
    }

    @MainActor
    public func makePlayView(difficulty: Difficulty,
                             onComplete: @escaping @MainActor (GameResult) -> Void) -> some View {
        HoderegningWatchPlayView(
            config: .forDifficulty(difficulty),
            difficulty: difficulty,
            onComplete: onComplete
        )
    }
}

struct HoderegningWatchIntroView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "plus.forwardslash.minus")
                .font(.title)
                .foregroundStyle(Color.accentColor)
            Text("Hoderegning")
                .font(.headline)
            Text("Velg riktig svar blant fire.")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }
}
