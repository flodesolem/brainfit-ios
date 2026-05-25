import SwiftUI

public protocol Game {
    associatedtype IntroView: View
    associatedtype PlayView: View

    static var metadata: GameMetadata { get }

    @MainActor
    func makeIntroView() -> IntroView

    @MainActor
    func makePlayView(difficulty: Difficulty,
                      onComplete: @escaping @MainActor (GameResult) -> Void) -> PlayView
}

public extension Game {
    static var id: String { metadata.id }
}

public struct AnyGame {
    public let metadata: GameMetadata
    private let _makeIntroView: @MainActor () -> AnyView
    private let _makePlayView: @MainActor (Difficulty, @escaping @MainActor (GameResult) -> Void) -> AnyView

    @MainActor
    public init<G: Game>(_ game: G) {
        self.metadata = G.metadata
        let captured = game
        self._makeIntroView = { @MainActor in AnyView(captured.makeIntroView()) }
        self._makePlayView = { @MainActor difficulty, onComplete in
            AnyView(captured.makePlayView(difficulty: difficulty, onComplete: onComplete))
        }
    }

    @MainActor
    public func makeIntroView() -> AnyView { _makeIntroView() }

    @MainActor
    public func makePlayView(difficulty: Difficulty,
                             onComplete: @escaping @MainActor (GameResult) -> Void) -> AnyView {
        _makePlayView(difficulty, onComplete)
    }
}
