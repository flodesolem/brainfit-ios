import SwiftUI

public struct TapTheColorGame: Game {
    public init() {}

    public static let metadata = GameMetadata(
        id: "tap-the-color",
        displayName: "Riktig Farge",
        category: .attention,
        shortDescription: "Trykk fargen ordet er skrevet i — ikke ordet selv",
        icon: "paintpalette.fill",
        targetDurationSeconds: 30
    )

    @MainActor
    public func makeIntroView() -> some View {
        TapTheColorIntroView()
    }

    @MainActor
    public func makePlayView(difficulty: Difficulty,
                             onComplete: @escaping @MainActor (GameResult) -> Void) -> some View {
        StroopPlayView(
            config: .forDifficulty(difficulty),
            difficulty: difficulty,
            onComplete: onComplete
        )
    }
}

struct TapTheColorIntroView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)
            Text("Riktig Farge")
                .font(.largeTitle.bold())
            Text("Trykk fargen ordet er skrevet i. Hvis ordet er «RØD» og det er skrevet i blått, trykker du BLÅ.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}
