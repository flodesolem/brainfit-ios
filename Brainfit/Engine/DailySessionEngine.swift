import Foundation

@MainActor
public final class DailySessionEngine {
    private let runs: any GameRunRepository
    private let streaks: any StreakRepository
    private let calendar: Calendar
    private let now: @MainActor () -> Date

    public init(runs: any GameRunRepository,
                streaks: any StreakRepository,
                calendar: Calendar = .current,
                now: @escaping @MainActor () -> Date = { Date() }) {
        self.runs = runs
        self.streaks = streaks
        self.calendar = calendar
        self.now = now
    }

    public func currentStreak() -> Int {
        (try? streaks.load().currentStreak) ?? 0
    }

    public func longestStreak() -> Int {
        (try? streaks.load().longestStreak) ?? 0
    }

    public func recommendedDifficulty(forGameId gameId: String) throws -> Difficulty {
        let recent = try runs.recent(forGameId: gameId, limit: 5)
        guard let last = recent.first else { return .medium }
        let scores = recent.map(\.score)
        return ScoreCalculator.recommendDifficulty(currentLevel: last.difficultyEnum, recentScores: scores)
    }

    /// Velger tilfeldig N spill for dagens økt, deterministisk per dato.
    /// Samme dag = samme utvalg (slik at brukeren ikke får ny økt hvis han åpner appen flere ganger).
    /// Neste dag = nytt seed = annet utvalg.
    public func todaysGameIds(from registry: GameRegistry, count: Int = 3) -> [String] {
        let allIds = registry.allGames.map(\.metadata.id).sorted()
        if allIds.count <= count { return allIds }

        let day = calendar.startOfDay(for: now())
        let seed = UInt64(bitPattern: Int64(day.timeIntervalSince1970))
        var rng = SystemRandomNumberGeneratorBox(seed: seed)
        let shuffled = allIds.shuffled(using: &rng)
        return Array(shuffled.prefix(count))
    }

    public func didCompleteSessionToday() -> Bool {
        guard let state = try? streaks.load(),
              let last = state.lastSessionDate else { return false }
        return calendar.startOfDay(for: last) == calendar.startOfDay(for: now())
    }

    public func recordCompletion(score: Int) throws {
        let state = try streaks.load()
        let today = calendar.startOfDay(for: now())

        if let last = state.lastSessionDate {
            let lastDay = calendar.startOfDay(for: last)
            if lastDay == today {
                // Samme dag — streak uendret
                state.lastSessionDate = now()
                try streaks.save(state)
                return
            }
            let hoursSince = now().timeIntervalSince(last) / 3600
            if hoursSince > 36 {
                state.currentStreak = 1
            } else {
                state.currentStreak += 1
            }
        } else {
            state.currentStreak = 1
        }
        state.longestStreak = max(state.longestStreak, state.currentStreak)
        state.lastSessionDate = now()
        try streaks.save(state)
    }
}
