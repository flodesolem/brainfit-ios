import SwiftUI

public struct TapTheColorWatchGame: Game {
    public init() {}

    public static let metadata = GameMetadata(
        id: "tap-the-color",
        displayName: "Riktig Farge",
        category: .attention,
        shortDescription: "Trykk fargen ordet er skrevet i",
        icon: "paintpalette.fill",
        targetDurationSeconds: 30
    )

    @MainActor
    public func makeIntroView() -> some View {
        TapTheColorWatchIntroView()
    }

    @MainActor
    public func makePlayView(difficulty: Difficulty,
                             onComplete: @escaping @MainActor (GameResult) -> Void) -> some View {
        StroopWatchPlayView(
            config: .forDifficulty(difficulty),
            difficulty: difficulty,
            onComplete: onComplete
        )
    }
}

struct TapTheColorWatchIntroView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "paintpalette.fill")
                .font(.title)
                .foregroundStyle(Color.accentColor)
            Text("Riktig Farge")
                .font(.headline)
            Text("Trykk fargen ordet er skrevet i.")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }
}
