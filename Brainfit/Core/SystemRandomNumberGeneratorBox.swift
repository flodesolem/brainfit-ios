import Foundation

/// Determinisme: SeedableRNG-wrapper for tester og daglige spill-utvalg.
/// LCG (linear congruential generator) — deterministisk gitt samme seed.
public struct SystemRandomNumberGeneratorBox: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64?) {
        self.state = seed ?? UInt64.random(in: .min ... .max)
    }

    public mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }

    public mutating func nextUInt64() -> UInt64 { next() }
}
