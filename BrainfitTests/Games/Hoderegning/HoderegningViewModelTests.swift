import XCTest
@testable import Brainfit

@MainActor
final class HoderegningViewModelTests: XCTestCase {
    func testSeededInitIsDeterministic() {
        let a = HoderegningViewModel(config: .forDifficulty(.medium), seed: 42)
        let b = HoderegningViewModel(config: .forDifficulty(.medium), seed: 42)
        XCTAssertEqual(a.currentStimulus.operandA, b.currentStimulus.operandA)
        XCTAssertEqual(a.currentStimulus.operandB, b.currentStimulus.operandB)
        XCTAssertEqual(a.currentStimulus.op, b.currentStimulus.op)
        XCTAssertEqual(a.currentStimulus.correctAnswer, b.currentStimulus.correctAnswer)
        XCTAssertEqual(a.currentStimulus.options, b.currentStimulus.options)
    }

    func testCorrectAnswerIncrementsCorrectAndStreak() {
        let vm = HoderegningViewModel(config: .forDifficulty(.medium), seed: 1)
        let answer = vm.currentStimulus.correctAnswer
        vm.registerAnswer(answer)
        XCTAssertEqual(vm.correct, 1)
        XCTAssertEqual(vm.incorrect, 0)
        XCTAssertEqual(vm.currentStreak, 1)
        XCTAssertEqual(vm.bestStreak, 1)
    }

    func testIncorrectAnswerIncrementsIncorrectAndResetsStreak() {
        let vm = HoderegningViewModel(config: .forDifficulty(.medium), seed: 7)
        // Pick an option that is definitely wrong.
        let wrong = vm.currentStimulus.options.first { $0 != vm.currentStimulus.correctAnswer }!
        // First, build up a streak.
        let correct = vm.currentStimulus.correctAnswer
        vm.registerAnswer(correct)
        XCTAssertEqual(vm.currentStreak, 1)
        // Then a wrong answer should reset current streak but keep best.
        vm.registerAnswer(wrong)
        XCTAssertEqual(vm.incorrect, 1)
        XCTAssertEqual(vm.currentStreak, 0)
        XCTAssertEqual(vm.bestStreak, 1)
    }

    func testOptionsAlwaysIncludeCorrectAnswerAndAreUnique() {
        for seed in UInt64(0)..<UInt64(20) {
            for difficulty in [Difficulty.easy, .medium, .hard] {
                let vm = HoderegningViewModel(config: .forDifficulty(difficulty), seed: seed)
                let options = vm.currentStimulus.options
                XCTAssertEqual(options.count, 4, "Expected 4 options for seed=\(seed) difficulty=\(difficulty)")
                XCTAssertEqual(Set(options).count, 4, "Options should be unique for seed=\(seed) difficulty=\(difficulty)")
                XCTAssertTrue(options.contains(vm.currentStimulus.correctAnswer),
                              "Options must include correct answer for seed=\(seed) difficulty=\(difficulty)")
            }
        }
    }

    func testEasyDifficultyOnlyUsesAddAndSubtract() {
        for seed in UInt64(0)..<UInt64(30) {
            let vm = HoderegningViewModel(config: .forDifficulty(.easy), seed: seed)
            XCTAssertNotEqual(vm.currentStimulus.op, .multiply,
                              "Easy must not produce multiplication (seed=\(seed))")
        }
    }

    func testEasyDoesNotProduceNegativeAnswer() {
        for seed in UInt64(0)..<UInt64(30) {
            let vm = HoderegningViewModel(config: .forDifficulty(.easy), seed: seed)
            XCTAssertGreaterThanOrEqual(vm.currentStimulus.correctAnswer, 0,
                                         "Easy must not produce negative answer (seed=\(seed))")
        }
    }

    func testFinalResultReportsCorrectGameId() {
        let vm = HoderegningViewModel(config: .forDifficulty(.medium), seed: 1)
        let result = vm.finalResult(difficulty: .medium, durationSeconds: 60)
        XCTAssertEqual(result.gameId, "hoderegning")
        XCTAssertNotNil(result.rawMetrics["correct"])
        XCTAssertNotNil(result.rawMetrics["incorrect"])
        XCTAssertNotNil(result.rawMetrics["avgMs"])
        XCTAssertNotNil(result.rawMetrics["streak"])
    }

    func testNextStimulusIsGeneratedAfterAnswer() {
        let vm = HoderegningViewModel(config: .forDifficulty(.medium), seed: 99)
        let first = vm.currentStimulus.id
        vm.registerAnswer(vm.currentStimulus.correctAnswer)
        XCTAssertNotEqual(vm.currentStimulus.id, first)
    }
}
