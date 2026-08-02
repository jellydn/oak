import XCTest
@testable import Oak

internal final class SessionCycleTests: XCTestCase {
    private let workDuration = 1500
    private let breakDuration = 300
    private let longBreakDuration = 900
    private let roundsBeforeLongBreak = 4

    func testWorkCompletionIncrementsRound() {
        var cycle = SessionCycle(currentDate: day(1))

        cycle.startWork(currentDate: day(1))
        XCTAssertEqual(cycle.complete(currentDate: day(1)), .work)
        XCTAssertEqual(cycle.completedRounds, 1)
        XCTAssertTrue(cycle.isWorkSession)
    }

    func testBreakIntervalsUseShortBreakUntilThreshold() {
        var cycle = SessionCycle(currentDate: day(1))

        for _ in 1 ... 3 {
            cycle.startWork(currentDate: day(1))
            XCTAssertEqual(cycle.complete(currentDate: day(1)), .work)
            let interval = cycle.startNext(
                after: true,
                currentDate: day(1),
                configuration: configuration
            )
            XCTAssertEqual(interval.duration, breakDuration)
            XCTAssertFalse(interval.isWorkSession)
            XCTAssertFalse(interval.isLongBreak)
            XCTAssertEqual(cycle.complete(currentDate: day(1)), .shortBreak)
        }
    }

    func testBreakAtThresholdUsesLongBreakAndResetsRounds() {
        var cycle = SessionCycle(currentDate: day(1))

        cycle.startWork(currentDate: day(1))
        XCTAssertEqual(cycle.complete(currentDate: day(1)), .work)

        for _ in 1 ..< roundsBeforeLongBreak {
            let shortBreak = cycle.startNext(
                after: true,
                currentDate: day(1),
                configuration: configuration
            )
            XCTAssertFalse(shortBreak.isLongBreak)
            XCTAssertEqual(cycle.complete(currentDate: day(1)), .shortBreak)
            cycle.startNext(
                after: false,
                currentDate: day(1),
                configuration: configuration
            )
            XCTAssertEqual(cycle.complete(currentDate: day(1)), .work)
        }

        let longBreak = cycle.startNext(
            after: true,
            currentDate: day(1),
            configuration: configuration
        )
        XCTAssertTrue(longBreak.isLongBreak)
        XCTAssertEqual(longBreak.duration, longBreakDuration)
        XCTAssertEqual(cycle.complete(currentDate: day(1)), .longBreak)
        XCTAssertEqual(cycle.completedRounds, 0)
    }

    func testNewDayClearsRoundCountBeforeSelectingBreak() {
        var cycle = SessionCycle(currentDate: day(1))
        cycle.startWork(currentDate: day(1))
        XCTAssertEqual(cycle.complete(currentDate: day(1)), .work)
        cycle.startNext(
            after: true,
            currentDate: day(1),
            configuration: configuration
        )
        XCTAssertEqual(cycle.complete(currentDate: day(1)), .shortBreak)

        let nextDayInterval = cycle.startNext(
            after: true,
            currentDate: day(2),
            configuration: .init(
                workDuration: workDuration,
                breakDuration: breakDuration,
                longBreakDuration: longBreakDuration,
                roundsBeforeLongBreak: roundsBeforeLongBreak
            )
        )
        XCTAssertFalse(nextDayInterval.isLongBreak)
        XCTAssertEqual(nextDayInterval.duration, breakDuration)
        XCTAssertEqual(cycle.completedRounds, 0)
    }

    private var configuration: SessionCycle.Configuration {
        .init(
            workDuration: workDuration,
            breakDuration: breakDuration,
            longBreakDuration: longBreakDuration,
            roundsBeforeLongBreak: roundsBeforeLongBreak
        )
    }

    private func day(_ value: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 1, day: value))!
    }
}
