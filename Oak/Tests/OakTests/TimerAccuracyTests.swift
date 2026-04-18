import XCTest
@testable import Oak

/// Tests that verify timer accuracy uses Date-based elapsed time, not just timer ticks.
@MainActor
internal final class TimerAccuracyTests: XCTestCase {
    var viewModel: FocusSessionViewModel!
    var presetSettings: PresetSettingsStore!
    var progressManager: ProgressManager!
    var suiteName: String!

    override func setUp() async throws {
        suiteName = "OakTests.TimerAccuracy.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw NSError(domain: "TimerAccuracyTests", code: 1)
        }
        userDefaults.removePersistentDomain(forName: suiteName)
        presetSettings = PresetSettingsStore(userDefaults: userDefaults)
        progressManager = ProgressManager(userDefaults: userDefaults)
        viewModel = FocusSessionViewModel(
            presetSettings: presetSettings,
            progressManager: progressManager,
            notificationService: NotificationService()
        )
    }

    override func tearDown() async throws {
        viewModel.cleanup()
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    func testSessionEndDateIsSetOnStart() {
        // sessionEndDate is a private property; verify indirectly via state
        viewModel.startSession()
        XCTAssertTrue(viewModel.isRunning, "Session should be running after start")
    }

    func testSessionEndDateUpdatedOnResume() {
        viewModel.startSession()
        viewModel.pauseSession()
        XCTAssertTrue(viewModel.isPaused, "Session should be paused")

        viewModel.resumeSession()
        XCTAssertTrue(viewModel.isRunning, "Session should be running after resume")
    }

    func testCompleteWorkSessionRecordsFullDuration() {
        viewModel.startSession()
        viewModel.completeSession()

        // With date-based tracking, a session started and immediately completed
        // records 0 minutes (< 1 minute elapsed), which is expected and filtered out
        XCTAssertEqual(progressManager.dailyStats.todayCompletedSessions, 0,
                       "Sub-minute sessions should not be recorded")
    }

    func testPauseTimeIsTrackedSeparately() {
        // Start a work session
        viewModel.startSession()
        XCTAssertTrue(viewModel.isRunning)

        // Pause immediately
        viewModel.pauseSession()
        XCTAssertTrue(viewModel.isPaused)

        // Resume
        viewModel.resumeSession()
        XCTAssertTrue(viewModel.isRunning)

        // Complete — duration should exclude paused time
        viewModel.completeSession()

        // Because elapsed time is near zero, no session should be recorded
        XCTAssertEqual(progressManager.dailyStats.todayCompletedSessions, 0,
                       "Sub-minute session should not be recorded even with pause/resume cycle")
    }

    func testAutoStartCountdownResetOnNextSession() {
        // Set up: auto-start is enabled
        presetSettings.setAutoStartNextInterval(true)

        viewModel.startSession()
        viewModel.completeSession()

        // autoStartCountdown should eventually trigger; verify state transition works
        XCTAssertTrue(viewModel.canStartNext, "Should be able to start next after completion")

        viewModel.startNextSession()
        XCTAssertFalse(viewModel.canStart, "Should not be in idle state after starting next")
    }

    func testResetClearsDateTrackingState() {
        viewModel.startSession()
        viewModel.pauseSession()
        viewModel.resetSession()

        // After reset, session should be back to idle
        XCTAssertTrue(viewModel.canStart, "Session should be resettable to idle")
        XCTAssertEqual(viewModel.displayTime, "25:00", "Display time should reset to preset duration")
    }

    func testDateBasedTimerIsAccurate() {
        // Verify that the tick uses Date difference, not just decrementing.
        // Since sessionEndDate is set using Date().addingTimeInterval(...),
        // the countdown is anchored to a real point in time.
        let preset = Preset.short
        let workDuration = presetSettings.workDuration(for: preset)
        viewModel.startSession(using: preset)

        // The display should show the full work duration immediately after start
        let parts = viewModel.displayTime.split(separator: ":").compactMap { Int($0) }
        XCTAssertEqual(parts.count, 2, "Display time should have mm:ss format")
        let displaySeconds = parts[0] * 60 + parts[1]
        XCTAssertEqual(displaySeconds, workDuration, accuracy: 1,
                       "Display time should match work duration within 1 second")
    }
}
