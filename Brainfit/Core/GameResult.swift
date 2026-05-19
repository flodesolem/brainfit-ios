import Foundation

public struct GameResult: Sendable, Equatable {
    public let gameId: String
    public let score: Int
    public let accuracy: Double
    public let durationSeconds: Double
    public let difficulty: Difficulty
    public let rawMetrics: [String: Double]

    public init(gameId: String,
                score: Int,
                accuracy: Double,
                durationSeconds: Double,
                difficulty: Difficulty,
                rawMetrics: [String: Double]) {
        self.gameId = gameId
        self.score = score
        self.accuracy = accuracy
        self.durationSeconds = durationSeconds
        self.difficulty = difficulty
        self.rawMetrics = rawMetrics
    }

    public func rawMetricsJSON() throws -> String {
        let data = try JSONSerialization.data(withJSONObject: rawMetrics, options: [.sortedKeys])
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    public static func decodeRawMetrics(from json: String) throws -> [String: Double] {
        guard let data = json.data(using: .utf8) else { return [:] }
        let object = try JSONSerialization.jsonObject(with: data)
        guard let dict = object as? [String: Any] else {
            throw NSError(domain: "GameResult", code: 1, userInfo: [NSLocalizedDescriptionKey: "rawMetrics JSON must be an object"])
        }
        return dict.compactMapValues { value in
            if let double = value as? Double { return double }
            if let int = value as? Int { return Double(int) }
            return nil
        }
    }
}
