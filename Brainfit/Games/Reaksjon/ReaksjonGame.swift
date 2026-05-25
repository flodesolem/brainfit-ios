import SwiftUI

public struct ReaksjonGame: Game {
    public init() {}

    public static let metadata = GameMetadata(
        id: "reaksjon",
        displayName: "Reaksjon",
        category: .reaction,
        shortDescription: "Tapp så fort du kan når sirkelen blir grønn",
        icon: "bolt.fill",
        targetDurationSeconds: 30
    )

    @MainActor
    public func makeIntroView() -> some View {
        ReaksjonIntroView()
    }

    @MainActor
    public func makePlayView(difficulty: Difficulty,
                             onComplete: @escaping @MainActor (GameResult) -> Void) -> some View {
        ReaksjonPlayView(
            config: .forDifficulty(difficulty),
            difficulty: difficulty,
            onComplete: onComplete
        )
    }
}

struct ReaksjonIntroView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)
            Text("Reaksjon")
                .font(.largeTitle.bold())
            Text("Tapp skjermen så fort du kan når den grå sirkelen blir grønn. Ikke tapp før — det gir straffetid.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}
