import XCTest
@testable import Brainfit

@MainActor
final class NBackViewModelTests: XCTestCase {
    func testSameSeedProducesSameStimuli() {
        let vm1 = NBackViewModel(config: .forDifficulty(.medium), seed: 42)
        let vm2 = NBackViewModel(config: .forDifficulty(.medium), seed: 42)
        let positions1 = vm1.stimuli.map(\.position)
        let positions2 = vm2.stimuli.map(\.position)
        XCTAssertEqual(positions1, positions2)
    }

    func testGenerates20StimuliForMVPConfig() {
        let vm = NBackViewModel(config: .forDifficulty(.medium), seed: 7)
        XCTAssertEqual(vm.stimuli.count, 20)
    }

    func testTargetsExistAtFirstNIndicesOrLater() {
        let vm = NBackViewModel(config: .forDifficulty(.medium), seed: 99)
        // De første n stimuli kan ikke være targets
        for i in 0..<vm.config.n {
            XCTAssertFalse(vm.stimuli[i].isTarget)
        }
    }

    func testRegisteringMatchOnTargetIncrementsHits() {
        let vm = NBackViewModel(config: .forDifficulty(.easy), seed: 1)
        vm.advanceToNext()
        // Plasser fram til vi finner et target
        while vm.currentIndex < vm.stimuli.count - 1 && !(vm.currentStimulus?.isTarget ?? false) {
            vm.advanceToNext()
        }
        if vm.currentStimulus?.isTarget == true {
            let before = vm.hits
            vm.registerMatchTap()
            XCTAssertEqual(vm.hits, before + 1)
        }
    }
}
