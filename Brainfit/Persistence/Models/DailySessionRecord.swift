import Foundation
import SwiftData

@Model
public final class DailySessionRecord {
    public var id: UUID = UUID()
    public var date: Date = Date()
    public var completedAt: Date?
    public var gameRunIds: [UUID] = []
    public var totalScore: Int = 0

    public init(date: Date,
                completedAt: Date? = nil,
                gameRunIds: [UUID] = [],
                totalScore: Int = 0) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.completedAt = completedAt
        self.gameRunIds = gameRunIds
        self.totalScore = totalScore
    }
}
