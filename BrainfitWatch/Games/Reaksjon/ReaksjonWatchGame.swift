import SwiftUI

public struct ReaksjonWatchGame: Game {
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
        ReaksjonWatchIntroView()
    }

    @MainActor
    public func makePlayView(difficulty: Difficulty,
                             onComplete: @escaping @MainActor (GameResult) -> Void) -> some View {
        ReaksjonWatchPlayView(
            config: .forDifficulty(difficulty),
            difficulty: difficulty,
            onComplete: onComplete
        )
    }
}

struct ReaksjonWatchIntroView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(.title)
                .foregroundStyle(Color.accentColor)
            Text("Reaksjon")
                .font(.headline)
            Text("Tapp når sirkelen blir grønn.")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }
}
