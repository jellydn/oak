import XCTest
@testable import OakIOS

internal final class FocusProgressRepositoryTests: XCTestCase {
    func testSummaryCountsOnlyFocusCompletionsForToday() {
        let store = MemoryFocusProgressStore()
        let calendar = utcCalendar()
        let repository = FocusProgressRepository(store: store, calendar: calendar)
        let today = date(day: 3, calendar: calendar)

        repository.record(completion(endedAt: today, minutes: 25, kind: .focus))
        repository.record(completion(endedAt: today, minutes: 5, kind: .shortBreak))
        repository.record(completion(endedAt: date(day: 2, calendar: calendar), minutes: 50, kind: .focus))

        XCTAssertEqual(
            repository.summary(on: today),
            FocusProgressSummary(focusMinutes: 25, completedSessions: 1, streakDays: 2)
        )
    }

    func testStreakAllowsTodayToBeIncomplete() {
        let store = MemoryFocusProgressStore()
        let calendar = utcCalendar()
        let repository = FocusProgressRepository(store: store, calendar: calendar)
        let today = date(day: 5, calendar: calendar)

        repository.record(completion(endedAt: date(day: 4, calendar: calendar), minutes: 25, kind: .focus))
        repository.record(completion(endedAt: date(day: 3, calendar: calendar), minutes: 25, kind: .focus))
        repository.record(completion(endedAt: date(day: 1, calendar: calendar), minutes: 25, kind: .focus))

        XCTAssertEqual(repository.summary(on: today).streakDays, 2)
    }

    func testRecordingSameIntervalTwiceIsIdempotent() {
        let store = MemoryFocusProgressStore()
        let calendar = utcCalendar()
        let repository = FocusProgressRepository(store: store, calendar: calendar)
        let today = date(day: 3, calendar: calendar)
        let completion = completion(endedAt: today, minutes: 25, kind: .focus)

        repository.record(completion)
        repository.record(completion)

        XCTAssertEqual(
            repository.summary(on: today),
            FocusProgressSummary(focusMinutes: 25, completedSessions: 1, streakDays: 1)
        )
    }

    private func completion(
        endedAt: Date,
        minutes: Int,
        kind: FocusIntervalKind
    ) -> CompletedFocusInterval {
        CompletedFocusInterval(
            kind: kind,
            startedAt: endedAt.addingTimeInterval(TimeInterval(-minutes * 60)),
            endedAt: endedAt,
            durationSeconds: minutes * 60
        )
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(day: Int, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: 12))!
    }
}

private final class MemoryFocusProgressStore: FocusProgressStoring {
    private var records: [FocusSessionRecord] = []

    func load() -> [FocusSessionRecord] {
        records
    }

    func save(_ records: [FocusSessionRecord]) {
        self.records = records
    }
}
