import XCTest
@testable import Oak

internal final class SessionEngineTests: XCTestCase {
    // MARK: - Helpers

    private static let testConfig = SessionConfig(
        workSeconds: 25 * 60,
        breakSeconds: 5 * 60,
        longBreakSeconds: 15 * 60,
        roundsBeforeLongBreak: 4,
        playSoundOnSessionCompletion: true,
        playSoundOnBreakCompletion: true,
        autoStartNextInterval: false
    )

    private func makeEngine(
        config: SessionConfig = testConfig,
        calendar: Calendar = .current,
        now: Date = Date(timeIntervalSince1970: 1700000000)
    ) -> SessionEngine {
        SessionEngine(config: config, calendar: calendar, now: now)
    }

    private func at(
        _ offsetSeconds: TimeInterval,
        base: Date = Date(timeIntervalSince1970: 1700000000)
    ) -> Date {
        base.addingTimeInterval(offsetSeconds)
    }

    // MARK: - Initial state

    func testEngineStartsIdleWithZeroRounds() {
        let engine = makeEngine()
        XCTAssertEqual(engine.state, .idle)
        XCTAssertEqual(engine.completedRounds, 0)
        XCTAssertNil(engine.nextSessionPreview)
    }

    // MARK: - Start

    func testStartFromIdleEntersRunningWork() {
        var engine = makeEngine(now: at(0))
        let intents = engine.apply(.start(now: at(0)))
        XCTAssertEqual(intents, [])
        XCTAssertEqual(engine.state, .running(remainingSeconds: 25 * 60, kind: .work))
    }

    func testStartIgnoredWhileRunning() {
        var engine = makeEngine(now: at(0))
        _ = engine.apply(.start(now: at(0)))
        let intents = engine.apply(.start(now: at(1)))
        XCTAssertEqual(intents, [])
        XCTAssertEqual(engine.state, .running(remainingSeconds: 25 * 60, kind: .work))
    }

    // MARK: - Tick

    func testTickAdvancesRemainingSeconds() {
        var engine = makeEngine(now: at(0))
        _ = engine.apply(.start(now: at(0)))
        _ = engine.apply(.tick(now: at(60)))
        XCTAssertEqual(engine.state, .running(remainingSeconds: 24 * 60, kind: .work))
    }

    func testTickAtZeroCompletesWorkSession() {
        var engine = makeEngine(now: at(0))
        _ = engine.apply(.start(now: at(0)))
        let intents = engine.apply(.tick(now: at(TimeInterval(25 * 60))))

        XCTAssertEqual(engine.state, .completed(kind: .work))
        XCTAssertEqual(engine.completedRounds, 1)

        XCTAssertTrue(intents.contains(.notifyCompleted(kind: .work)))
        XCTAssertTrue(intents.contains(.stopAudio))
        XCTAssertTrue(intents.contains(.playCompletionSound))
        XCTAssertTrue(intents.contains(.flashCompletion))
        XCTAssertFalse(intents.contains(.scheduleAutoStartCountdown))
    }

    // MARK: - Pause / Resume

    func testPauseFromRunningEmitsPauseAudio() {
        var engine = makeEngine(now: at(0))
        _ = engine.apply(.start(now: at(0)))
        _ = engine.apply(.tick(now: at(60)))
        let intents = engine.apply(.pause(now: at(60)))
        XCTAssertEqual(intents, [.pauseAudio])
        XCTAssertEqual(engine.state, .paused(remainingSeconds: 24 * 60, kind: .work))
    }

    func testResumeFromPausedEmitsResumePausedAudio() {
        var engine = makeEngine(now: at(0))
        _ = engine.apply(.start(now: at(0)))
        _ = engine.apply(.tick(now: at(60)))
        _ = engine.apply(.pause(now: at(60)))
        let intents = engine.apply(.resume(now: at(120)))
        XCTAssertEqual(intents, [.resumePausedAudio])
        XCTAssertEqual(engine.state, .running(remainingSeconds: 24 * 60, kind: .work))
    }

    func testPauseIgnoredWhenNotRunning() {
        var engine = makeEngine(now: at(0))
        let intents = engine.apply(.pause(now: at(0)))
        XCTAssertEqual(intents, [])
        XCTAssertEqual(engine.state, .idle)
    }

    // MARK: - Long Break decision

    func testShortBreakIsChosenBeforeRoundsThreshold() {
        var engine = makeEngine(now: at(0))
        _ = engine.apply(.start(now: at(0)))
        _ = engine.apply(.tick(now: at(TimeInterval(25 * 60))))

        XCTAssertEqual(engine.nextSessionPreview, .shortBreak)

        _ = engine.apply(.startNext(now: at(TimeInterval(25 * 60)), isAutoStart: false))
        XCTAssertEqual(engine.state, .running(remainingSeconds: 5 * 60, kind: .shortBreak))
    }

    func testLongBreakIsChosenAfterFourCompletedRounds() {
        var engine = makeEngine(now: at(0))
        var elapsed: TimeInterval = 0

        _ = engine.apply(.start(now: at(elapsed))) // first work session

        for round in 1 ... 4 {
            elapsed += 25 * 60
            _ = engine.apply(.tick(now: at(elapsed))) // completes work
            XCTAssertEqual(engine.completedRounds, round)

            if round < 4 {
                _ = engine.apply(.startNext(now: at(elapsed), isAutoStart: false)) // break
                elapsed += 5 * 60
                _ = engine.apply(.tick(now: at(elapsed))) // completes break
                _ = engine.apply(.startNext(now: at(elapsed), isAutoStart: false)) // next work
            }
        }

        XCTAssertEqual(engine.completedRounds, 4)
        XCTAssertEqual(engine.state, .completed(kind: .work))
        XCTAssertEqual(engine.nextSessionPreview, .longBreak)

        _ = engine.apply(.startNext(now: at(elapsed), isAutoStart: false))
        XCTAssertEqual(engine.state, .running(remainingSeconds: 15 * 60, kind: .longBreak))
    }

    func testCompletingLongBreakResetsRoundsToZero() {
        var engine = makeEngine(
            config: SessionConfig(
                workSeconds: 25 * 60,
                breakSeconds: 5 * 60,
                longBreakSeconds: 15 * 60,
                roundsBeforeLongBreak: 1, // shortcut: long break after 1 round
                playSoundOnSessionCompletion: false,
                playSoundOnBreakCompletion: false,
                autoStartNextInterval: false
            ),
            now: at(0)
        )

        _ = engine.apply(.start(now: at(0)))
        _ = engine.apply(.tick(now: at(TimeInterval(25 * 60)))) // complete work, rounds=1
        XCTAssertEqual(engine.completedRounds, 1)

        _ = engine.apply(.startNext(now: at(TimeInterval(25 * 60)), isAutoStart: false))
        XCTAssertEqual(engine.state, .running(remainingSeconds: 15 * 60, kind: .longBreak))

        _ = engine.apply(.tick(now: at(TimeInterval(40 * 60)))) // complete long break
        XCTAssertEqual(engine.completedRounds, 0)
    }

    // MARK: - Day rollover

    func testNewDayResetsRoundsOnStart() {
        var engine = makeEngine(now: at(0))
        _ = engine.apply(.start(now: at(0)))
        _ = engine.apply(.tick(now: at(TimeInterval(25 * 60))))
        XCTAssertEqual(engine.completedRounds, 1)
        _ = engine.apply(.reset)

        // Move two days forward; `.start` should reset completed rounds.
        let nextDay = at(0).addingTimeInterval(2 * 24 * 60 * 60)
        _ = engine.apply(.start(now: nextDay))
        XCTAssertEqual(engine.completedRounds, 0)
    }

    // MARK: - Audio remember-and-resume

    func testWorkCompletionRemembersCurrentlyPlayingTrack() {
        var engine = makeEngine(now: at(0))
        engine.setCurrentlyPlayingAudio(.rain)
        _ = engine.apply(.start(now: at(0)))
        _ = engine.apply(.tick(now: at(TimeInterval(25 * 60))))

        // Next work start should emit `.startRememberedAudio(.rain)`.
        engine.setCurrentlyPlayingAudio(.none) // audio is stopped
        _ = engine.apply(.startNext(now: at(TimeInterval(25 * 60)), isAutoStart: false)) // .shortBreak
        let breakDone = at(TimeInterval(30 * 60))
        _ = engine.apply(.tick(now: breakDone)) // complete break
        let intents = engine.apply(.startNext(now: breakDone, isAutoStart: false))
        XCTAssertTrue(intents.contains(.startRememberedAudio(track: .rain)))
    }

    func testCompletionWithNoPlayingAudioDoesNotOverwriteRememberedTrack() {
        var engine = makeEngine(now: at(0))
        engine.setCurrentlyPlayingAudio(.rain)
        _ = engine.apply(.start(now: at(0)))
        _ = engine.apply(.tick(now: at(TimeInterval(25 * 60)))) // remembers rain

        engine.setCurrentlyPlayingAudio(.none)
        _ = engine.apply(.startNext(now: at(TimeInterval(25 * 60)), isAutoStart: false))
        _ = engine.apply(.tick(now: at(TimeInterval(30 * 60)))) // break completes, nothing playing

        // Rain should still be remembered. Next work start emits it.
        let intents = engine.apply(.startNext(now: at(TimeInterval(30 * 60)), isAutoStart: false))
        XCTAssertTrue(intents.contains(.startRememberedAudio(track: .rain)))
    }

    // MARK: - Completion sound config

    func testBreakCompletionSoundSuppressedOnAutoStartedBreak() {
        var engine = makeEngine(
            config: SessionConfig(
                workSeconds: 25 * 60,
                breakSeconds: 5 * 60,
                longBreakSeconds: 15 * 60,
                roundsBeforeLongBreak: 4,
                playSoundOnSessionCompletion: true,
                playSoundOnBreakCompletion: true,
                autoStartNextInterval: false
            ),
            now: at(0)
        )

        _ = engine.apply(.start(now: at(0)))
        _ = engine.apply(.tick(now: at(TimeInterval(25 * 60)))) // complete work
        _ = engine.apply(.startNext(now: at(TimeInterval(25 * 60)), isAutoStart: true)) // auto-started break
        let intents = engine.apply(.tick(now: at(TimeInterval(30 * 60)))) // complete break

        XCTAssertFalse(
            intents.contains(.playCompletionSound),
            "Break completion sound should not play when break was auto-started"
        )
    }

    func testAutoStartNextScheduledOnCompletionWhenEnabled() {
        var engine = makeEngine(
            config: SessionConfig(
                workSeconds: 25 * 60,
                breakSeconds: 5 * 60,
                longBreakSeconds: 15 * 60,
                roundsBeforeLongBreak: 4,
                playSoundOnSessionCompletion: false,
                playSoundOnBreakCompletion: false,
                autoStartNextInterval: true
            ),
            now: at(0)
        )

        _ = engine.apply(.start(now: at(0)))
        let intents = engine.apply(.tick(now: at(TimeInterval(25 * 60))))
        XCTAssertTrue(intents.contains(.scheduleAutoStartCountdown))
    }

    // MARK: - Recording

    func testCompletionEmitsRecordWithCorrectKindAndDuration() {
        var engine = makeEngine(now: at(0))
        _ = engine.apply(.start(now: at(0)))
        let intents = engine.apply(.tick(now: at(TimeInterval(25 * 60))))

        let record = intents.compactMap { intent -> SessionRecord? in
            if case let .recordCompletion(record) = intent { return record }
            return nil
        }.first

        XCTAssertNotNil(record)
        XCTAssertEqual(record?.type, .work)
        XCTAssertEqual(record?.durationMinutes, 25)
    }

    // MARK: - Reset

    func testResetReturnsToIdleAndStopsAudio() {
        var engine = makeEngine(now: at(0))
        _ = engine.apply(.start(now: at(0)))
        let intents = engine.apply(.reset)
        XCTAssertEqual(intents, [.stopAudio])
        XCTAssertEqual(engine.state, .idle)
        XCTAssertEqual(engine.completedRounds, 0)
    }
}
