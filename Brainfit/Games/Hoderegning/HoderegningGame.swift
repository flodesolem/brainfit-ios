import SwiftUI

public struct HoderegningGame: Game {
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
        HoderegningIntroView()
    }

    @MainActor
    public func makePlayView(difficulty: Difficulty,
                             onComplete: @escaping @MainActor (GameResult) -> Void) -> some View {
        HoderegningPlayView(
            config: .forDifficulty(difficulty),
            difficulty: difficulty,
            onComplete: onComplete
        )
    }
}

struct HoderegningIntroView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.forwardslash.minus")
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)
            Text("Hoderegning")
                .font(.largeTitle.bold())
            Text("Regn raskt — velg riktig svar blant fire. Flest riktige på 60 sekunder.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}
