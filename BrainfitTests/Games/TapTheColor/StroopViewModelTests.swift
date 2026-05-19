import XCTest
@testable import Brainfit

@MainActor
final class StroopViewModelTests: XCTestCase {
    func testCorrectAnswerIncrementsCorrect() {
        let vm = StroopViewModel(config: .forDifficulty(.medium), seed: 1)
        let actualInk = vm.currentStimulus.inkColor
        vm.registerAnswer(actualInk)
        XCTAssertEqual(vm.correct, 1)
        XCTAssertEqual(vm.incorrect, 0)
    }

    func testIncorrectAnswerIncrementsIncorrect() {
        let vm = StroopViewModel(config: .forDifficulty(.medium), seed: 2)
        let wrong = StroopColor.allCases.first { $0 != vm.currentStimulus.inkColor }!
        vm.registerAnswer(wrong)
        XCTAssertEqual(vm.correct, 0)
        XCTAssertEqual(vm.incorrect, 1)
    }

    func testOptionsCountMatchesDifficulty() {
        XCTAssertEqual(StroopViewModel(config: .forDifficulty(.easy), seed: 1).options.count, 3)
        XCTAssertEqual(StroopViewModel(config: .forDifficulty(.medium), seed: 1).options.count, 4)
        XCTAssertEqual(StroopViewModel(config: .forDifficulty(.hard), seed: 1).options.count, 5)
    }

    func testFinalResultReportsCorrectGameId() {
        let vm = StroopViewModel(config: .forDifficulty(.medium), seed: 1)
        let result = vm.finalResult(difficulty: .medium, durationSeconds: 30)
        XCTAssertEqual(result.gameId, "tap-the-color")
    }
}
