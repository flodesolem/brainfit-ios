import SwiftUI

public struct NBackGame: Game {
    public init() {}

    public static let metadata = GameMetadata(
        id: "nback",
        displayName: "Husk Mønsteret",
        category: .memory,
        shortDescription: "Trykk når posisjonen er lik den fra N runder siden",
        icon: "square.grid.3x3.fill",
        targetDurationSeconds: 60
    )

    @MainActor
    public func makeIntroView() -> some View {
        NBackIntroView()
    }

    @MainActor
    public func makePlayView(difficulty: Difficulty,
                             onComplete: @escaping @MainActor (GameResult) -> Void) -> some View {
        NBackPlayView(
            config: .forDifficulty(difficulty),
            difficulty: difficulty,
            onComplete: onComplete
        )
    }
}

struct NBackIntroView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)
            Text("Husk Mønsteret")
                .font(.largeTitle.bold())
            Text("En firkant blinker i et 3×3-rutenett. Trykk MATCH når posisjonen er den samme som N runder tilbake.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}
