import XCTest
import SwiftUI
@testable import Brainfit

private struct DummyGame: Game {
    static let metadata = GameMetadata(
        id: "dummy",
        displayName: "Dummy",
        category: .memory,
        shortDescription: "test",
        icon: "circle",
        targetDurationSeconds: 30
    )
    @MainActor func makeIntroView() -> some View { Text("intro") }
    @MainActor func makePlayView(difficulty: Difficulty, onComplete: @escaping @MainActor (GameResult) -> Void) -> some View {
        Text("play")
    }
}

final class GameRegistryTests: XCTestCase {
    @MainActor
    func testRegisteredGameCanBeRetrievedById() {
        let registry = GameRegistry()
        registry.register(DummyGame())
        XCTAssertEqual(registry.game(forId: "dummy")?.metadata.id, "dummy")
    }

    @MainActor
    func testRegistryIsEmptyByDefault() {
        XCTAssertEqual(GameRegistry().allGames.count, 0)
    }

    @MainActor
    func testRegisteringSameIdTwiceReplaces() {
        let registry = GameRegistry()
        registry.register(DummyGame())
        registry.register(DummyGame())
        XCTAssertEqual(registry.allGames.count, 1)
    }

    @MainActor
    func testGamesByCategoryFiltersCorrectly() {
        let registry = GameRegistry()
        registry.register(DummyGame())
        XCTAssertEqual(registry.games(in: .memory).count, 1)
        XCTAssertEqual(registry.games(in: .reaction).count, 0)
    }
}
