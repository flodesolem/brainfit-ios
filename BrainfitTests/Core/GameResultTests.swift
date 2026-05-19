import XCTest
@testable import Brainfit

final class GameResultTests: XCTestCase {
    func testEncodesAndDecodesRawMetrics() throws {
        let result = GameResult(
            gameId: "nback",
            score: 750,
            accuracy: 0.85,
            durationSeconds: 52.3,
            difficulty: .medium,
            rawMetrics: ["hits": 14, "misses": 3, "avgReactionMs": 620.5]
        )
        let json = try result.rawMetricsJSON()
        let decoded = try GameResult.decodeRawMetrics(from: json)
        XCTAssertEqual(decoded["hits"], 14)
        XCTAssertEqual(decoded["misses"], 3)
        XCTAssertEqual(decoded["avgReactionMs"], 620.5)
    }

    func testDecodingEmptyJSONReturnsEmptyDictionary() throws {
        XCTAssertEqual(try GameResult.decodeRawMetrics(from: "{}"), [:])
    }

    func testDecodingMalformedJSONThrows() {
        XCTAssertThrowsError(try GameResult.decodeRawMetrics(from: "not-json"))
    }
}
