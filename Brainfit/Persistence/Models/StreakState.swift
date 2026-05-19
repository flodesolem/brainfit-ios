import Foundation
import SwiftData

@Model
public final class StreakState {
    public var id: UUID = UUID()
    public var currentStreak: Int = 0
    public var longestStreak: Int = 0
    public var lastSessionDate: Date?

    public init(currentStreak: Int = 0,
                longestStreak: Int = 0,
                lastSessionDate: Date? = nil) {
        self.id = UUID()
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastSessionDate = lastSessionDate
    }
}
