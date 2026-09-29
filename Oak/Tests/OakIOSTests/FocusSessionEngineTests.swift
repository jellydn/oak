import XCTest
@testable import OakIOS

internal final class FocusSessionEngineTests: XCTestCase {
    func testPresetCanChangeOnlyWhileIdle() {
        var engine = FocusSessionEngine()
        let startDate = date(day: 1)

        engine.selectPreset(.long)
        XCTAssertEqual(engine.selectedPreset, .long)
        XCTAssertEqual(engine.remainingSeconds, 50 * 60)

        engine.start(now: startDate)
        engine.selectPreset(.short)

        XCTAssertEqual(engine.selectedPreset, .long)
        XCTAssertEqual(engine.intervalDuration, 50 * 60)
    }

    func testPauseAndResumeUseElapsedTime() {
        var engine = FocusSessionEngine()
        let startDate = date(day: 1)
        engine.start(now: startDate)

        engine.pause(now: startDate.addingTimeInterval(600))
        XCTAssertEqual(engine.phase, .paused)
        XCTAssertEqual(engine.remainingSeconds, 900)

        let resumeDate = startDate.addingTimeInterval(3600)
        engine.resume(now: resumeDate)
        XCTAssertNil(engine.refresh(now: resumeDate.addingTimeInterval(899)))
        XCTAssertEqual(engine.remainingSeconds, 1)

        let completion = engine.refresh(now: resumeDate.addingTimeInterval(900))
        XCTAssertEqual(completion?.kind, .focus)
        XCTAssertEqual(completion?.durationSeconds, 1500)
        XCTAssertEqual(engine.phase, .completed)
    }

    func testPauseAndResumePreserveFractionalRemainingTime() throws {
        var engine = FocusSessionEngine()
        let startDate = date(day: 1)
        engine.start(now: startDate)

        engine.pause(now: startDate.addingTimeInterval(600.25))
        let resumeDate = startDate.addingTimeInterval(3600)
        engine.resume(now: resumeDate)
        let resumedEndDate = try XCTUnwrap(engine.endDate)

        XCTAssertEqual(
            resumedEndDate.timeIntervalSince(resumeDate),
            899.75,
            accuracy: 0.0001
        )
        XCTAssertNil(engine.refresh(now: resumeDate.addingTimeInterval(899.74)))
        XCTAssertNotNil(engine.refresh(now: resumeDate.addingTimeInterval(899.75)))
    }

    func testFourthFocusSessionSelectsLongBreak() {
        var engine = FocusSessionEngine()
        var now = date(day: 1)
        engine.start(now: now)

        for round in 1 ... 4 {
            now = now.addingTimeInterval(TimeInterval(engine.intervalDuration))
            XCTAssertEqual(engine.refresh(now: now)?.kind, .focus)
            XCTAssertEqual(engine.completedFocusRounds, round)

            engine.startNext(now: now)
            if round < 4 {
                XCTAssertEqual(engine.intervalKind, .shortBreak)
                now = now.addingTimeInterval(TimeInterval(engine.intervalDuration))
                XCTAssertEqual(engine.refresh(now: now)?.kind, .shortBreak)
                engine.startNext(now: now)
            }
        }

        XCTAssertEqual(engine.intervalKind, .longBreak)
        XCTAssertEqual(engine.intervalDuration, 15 * 60)
    }

    func testResetRestoresSelectedPreset() {
        var engine = FocusSessionEngine()
        engine.selectPreset(.long)
        engine.start(now: date(day: 1))

        engine.reset()

        XCTAssertEqual(engine.phase, .idle)
        XCTAssertEqual(engine.intervalKind, .focus)
        XCTAssertEqual(engine.remainingSeconds, 50 * 60)
        XCTAssertEqual(engine.completedFocusRounds, 0)
    }

    private func date(day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: 12))!
    }
}
