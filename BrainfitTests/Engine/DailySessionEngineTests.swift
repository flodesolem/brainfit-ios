import XCTest
@testable import Brainfit

@MainActor
final class DailySessionEngineTests: XCTestCase {
    private final class FakeRunRepo: GameRunRepository, @unchecked Sendable {
        var stored: [GameRun] = []
        func save(_ run: GameRun) throws { stored.append(run) }
        func recent(forGameId gameId: String, limit: Int) throws -> [GameRun] {
            stored.filter { $0.gameId == gameId }.prefix(limit).map { $0 }
        }
        func all(since date: Date) throws -> [GameRun] {
            stored.filter { $0.playedAt >= date }
        }
    }

    private final class FakeStreakRepo: StreakRepository, @unchecked Sendable {
        var state = StreakState()
        func load() throws -> StreakState { state }
        func save(_ state: StreakState) throws { self.state = state }
    }

    func testFirstEverSessionStartsStreakAtOne() throws {
        let engine = DailySessionEngine(
            runs: FakeRunRepo(),
            streaks: FakeStreakRepo(),
            calendar: .current,
            now: { Date() }
        )
        try engine.recordCompletion(score: 500)
        XCTAssertEqual(engine.currentStreak(), 1)
    }

    func testTwoSessionsSameDayDoesNotIncrementStreak() throws {
        let engine = DailySessionEngine(
            runs: FakeRunRepo(),
            streaks: FakeStreakRepo(),
            calendar: .current,
            now: { Date() }
        )
        try engine.recordCompletion(score: 500)
        try engine.recordCompletion(score: 600)
        XCTAssertEqual(engine.currentStreak(), 1)
    }

    func testDidCompleteSessionTodayReflectsState() throws {
        let engine = DailySessionEngine(
            runs: FakeRunRepo(),
            streaks: FakeStreakRepo(),
            calendar: .current,
            now: { Date() }
        )
        XCTAssertFalse(engine.didCompleteSessionToday())
        try engine.recordCompletion(score: 500)
        XCTAssertTrue(engine.didCompleteSessionToday())
    }

    func testSessionOnConsecutiveDaysIncrementsStreak() throws {
        var fakeNow = Date(timeIntervalSince1970: 1_700_000_000)
        let engine = DailySessionEngine(
            runs: FakeRunRepo(),
            streaks: FakeStreakRepo(),
            calendar: .current,
            now: { fakeNow }
        )
        try engine.recordCompletion(score: 500)
        fakeNow = fakeNow.addingTimeInterval(86_400)
        try engine.recordCompletion(score: 600)
        XCTAssertEqual(engine.currentStreak(), 2)
    }

    func testSessionAfter36HoursBreaksStreak() throws {
        var fakeNow = Date(timeIntervalSince1970: 1_700_000_000)
        let engine = DailySessionEngine(
            runs: FakeRunRepo(),
            streaks: FakeStreakRepo(),
            calendar: .current,
            now: { fakeNow }
        )
        try engine.recordCompletion(score: 500)
        fakeNow = fakeNow.addingTimeInterval(36 * 3600 + 60) // 36t + 1 min
        try engine.recordCompletion(score: 500)
        XCTAssertEqual(engine.currentStreak(), 1)
    }

    func testDifficultyForFreshGameDefaultsToMedium() throws {
        let engine = DailySessionEngine(
            runs: FakeRunRepo(),
            streaks: FakeStreakRepo(),
            calendar: .current,
            now: { Date() }
        )
        XCTAssertEqual(try engine.recommendedDifficulty(forGameId: "nback"), .medium)
    }

    // MARK: - todaysGameIds

    func testTodaysGameIdsReturnsAllWhenLessThanRequested() {
        let engine = DailySessionEngine(runs: FakeRunRepo(), streaks: FakeStreakRepo(),
                                        calendar: .current, now: { Date() })
        let reg = GameRegistry()  // empty
        XCTAssertEqual(engine.todaysGameIds(from: reg, count: 3), [])
    }

    func testTodaysGameIdsIsDeterministicForSameDay() {
        let fixed = Date(timeIntervalSince1970: 1_700_000_000)
        let engine = DailySessionEngine(runs: FakeRunRepo(), streaks: FakeStreakRepo(),
                                        calendar: .current, now: { fixed })
        let reg = GameRegistry()
        reg.register(NBackGame())
        reg.register(TapTheColorGame())
        reg.register(HoderegningGame())
        reg.register(ReaksjonGame())

        let first = engine.todaysGameIds(from: reg, count: 3)
        let second = engine.todaysGameIds(from: reg, count: 3)
        XCTAssertEqual(first, second, "Samme dato skal gi samme utvalg")
        XCTAssertEqual(first.count, 3)
    }

    func testTodaysGameIdsChangesAcrossDays() {
        var fakeNow = Date(timeIntervalSince1970: 1_700_000_000)
        let engine = DailySessionEngine(runs: FakeRunRepo(), streaks: FakeStreakRepo(),
                                        calendar: .current, now: { fakeNow })
        let reg = GameRegistry()
        reg.register(NBackGame())
        reg.register(TapTheColorGame())
        reg.register(HoderegningGame())
        reg.register(ReaksjonGame())

        let day1 = engine.todaysGameIds(from: reg, count: 3)
        fakeNow = fakeNow.addingTimeInterval(86_400) // +1 dag
        let day2 = engine.todaysGameIds(from: reg, count: 3)
        // Med 4 spill og C(4,3)=4 mulige kombinasjoner, kan to forskjellige dager teoretisk havne på samme utvalg.
        // Vi sjekker at minst ÉN rotasjon skjer over flere dager.
        var sawDifference = (day1 != day2)
        for _ in 0..<5 where !sawDifference {
            fakeNow = fakeNow.addingTimeInterval(86_400)
            sawDifference = engine.todaysGameIds(from: reg, count: 3) != day1
        }
        XCTAssertTrue(sawDifference, "Skal rotere utvalget over flere dager")
    }

    func testTodaysGameIdsRespectsCountParameter() {
        let engine = DailySessionEngine(runs: FakeRunRepo(), streaks: FakeStreakRepo(),
                                        calendar: .current, now: { Date() })
        let reg = GameRegistry()
        reg.register(NBackGame())
        reg.register(TapTheColorGame())
        reg.register(HoderegningGame())
        reg.register(ReaksjonGame())

        XCTAssertEqual(engine.todaysGameIds(from: reg, count: 2).count, 2)
        XCTAssertEqual(engine.todaysGameIds(from: reg, count: 4).count, 4)
        XCTAssertEqual(engine.todaysGameIds(from: reg, count: 10).count, 4)  // capped
    }
}
