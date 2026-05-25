import XCTest
@testable import Brainfit

@MainActor
final class ReaksjonViewModelTests: XCTestCase {
    func testNextDelayIsDeterministicWithSameSeed() {
        let a = ReaksjonViewModel(config: .forDifficulty(.medium), seed: 42)
        let b = ReaksjonViewModel(config: .forDifficulty(.medium), seed: 42)
        for _ in 0..<10 {
            XCTAssertEqual(a.nextDelay(), b.nextDelay(), accuracy: 0.0001)
        }
    }

    func testNextDelayIsWithinConfiguredRange() {
        for difficulty in [Difficulty.easy, .medium, .hard] {
            let config = ReaksjonConfig.forDifficulty(difficulty)
            let vm = ReaksjonViewModel(config: config, seed: 7)
            for _ in 0..<50 {
                let delay = vm.nextDelay()
                XCTAssertGreaterThanOrEqual(delay, config.minDelaySeconds,
                                            "Delay must be >= min for \(difficulty)")
                XCTAssertLessThanOrEqual(delay, config.maxDelaySeconds,
                                          "Delay must be <= max for \(difficulty)")
            }
        }
    }

    func testRegisterTapInWaitingPhaseIncrementsFalseStarts() {
        let vm = ReaksjonViewModel(config: .forDifficulty(.medium), seed: 1)
        XCTAssertEqual(vm.phase, .waiting)
        vm.registerTap()
        XCTAssertEqual(vm.falseStarts, 1)
        XCTAssertEqual(vm.phase, .tooEarly)
        XCTAssertTrue(vm.reactionsMs.isEmpty)
    }

    func testRegisterTapInGoPhaseAppendsReaction() {
        let vm = ReaksjonViewModel(config: .forDifficulty(.medium), seed: 1)
        vm.goNow()
        XCTAssertEqual(vm.phase, .go)
        vm.registerTap()
        XCTAssertEqual(vm.reactionsMs.count, 1)
        XCTAssertEqual(vm.falseStarts, 0)
        XCTAssertEqual(vm.phase, .feedback)
        XCTAssertNotNil(vm.lastReactionMs)
    }

    func testAdvanceRoundMarksCompleteOnLastRound() {
        let config = ReaksjonConfig(rounds: 3, minDelaySeconds: 1.0, maxDelaySeconds: 2.0)
        let vm = ReaksjonViewModel(config: config, seed: 1)
        vm.advanceRound() // 1
        XCTAssertFalse(vm.isComplete)
        vm.advanceRound() // 2
        XCTAssertFalse(vm.isComplete)
        vm.advanceRound() // 3 — siste runde
        XCTAssertTrue(vm.isComplete)
    }

    func testAdvanceRoundResetsToWaitingWhenNotComplete() {
        let vm = ReaksjonViewModel(config: .forDifficulty(.medium), seed: 1)
        vm.goNow()
        vm.registerTap()
        XCTAssertEqual(vm.phase, .feedback)
        vm.advanceRound()
        XCTAssertEqual(vm.phase, .waiting)
        XCTAssertNil(vm.lastReactionMs)
    }

    func testRegisterTapIsIgnoredInTooEarlyAndFeedbackPhases() {
        let vm = ReaksjonViewModel(config: .forDifficulty(.medium), seed: 1)
        // Tap during waiting → tooEarly
        vm.registerTap()
        XCTAssertEqual(vm.phase, .tooEarly)
        let falseStartsBefore = vm.falseStarts
        // Additional tap in tooEarly should be ignored
        vm.registerTap()
        XCTAssertEqual(vm.falseStarts, falseStartsBefore)
        XCTAssertEqual(vm.phase, .tooEarly)
    }

    func testFinalResultReportsCorrectGameIdAndMetrics() {
        let vm = ReaksjonViewModel(config: .forDifficulty(.medium), seed: 1)
        vm.goNow()
        vm.registerTap()
        let result = vm.finalResult(difficulty: .medium)
        XCTAssertEqual(result.gameId, "reaksjon")
        XCTAssertNotNil(result.rawMetrics["avgMs"])
        XCTAssertNotNil(result.rawMetrics["bestMs"])
        XCTAssertNotNil(result.rawMetrics["falseStarts"])
    }

    func testAccuracyReflectsTapVersusFalseStartRatio() {
        let vm = ReaksjonViewModel(config: .forDifficulty(.medium), seed: 1)
        // 2 good reactions + 2 false starts → accuracy 0.5
        vm.goNow()
        vm.registerTap()
        vm.advanceRound()
        vm.goNow()
        vm.registerTap()
        vm.advanceRound()
        vm.registerTap() // waiting → tooEarly
        vm.advanceRound()
        vm.registerTap() // waiting → tooEarly
        let result = vm.finalResult(difficulty: .medium)
        XCTAssertEqual(result.accuracy, 0.5, accuracy: 0.001)
    }
}
