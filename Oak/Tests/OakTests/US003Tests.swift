import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class US003Tests: XCTestCase {
    var viewModel: FocusSessionViewModel!
    var presetSettings: PresetSettingsStore!
    var presetSuiteName: String!

    override func setUp() async throws {
        let suiteName = "OakTests.US003.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw NSError(domain: "US003Tests", code: 1)
        }
        userDefaults.removePersistentDomain(forName: suiteName)
        presetSuiteName = suiteName
        presetSettings = PresetSettingsStore(userDefaults: userDefaults)
        viewModel = FocusSessionViewModel(presetSettings: presetSettings)
    }

    override func tearDown() async throws {
        viewModel.cleanup()
        if let presetSuiteName {
            UserDefaults(suiteName: presetSuiteName)?.removePersistentDomain(forName: presetSuiteName)
        }
    }

    func testCanPauseActiveSession() {
        // Start a session
        viewModel.startSession()
        XCTAssertTrue(viewModel.canPause, "Should be able to pause active session")
        XCTAssertFalse(viewModel.canResume, "Should not be able to resume when not paused")
    }

    func testCanResumePausedSession() {
        // Start and then pause a session
        viewModel.startSession()
        viewModel.pauseSession()

        XCTAssertTrue(viewModel.canResume, "Should be able to resume paused session")
        XCTAssertFalse(viewModel.canPause, "Should not be able to pause when already paused")
    }

    func testTimePreservedAcrossPauseResume() {
        // Start session with short preset (25 minutes)
        viewModel.selectedPreset = .short
        viewModel.startSession()
        let initialTime = viewModel.displayTime
        XCTAssertEqual(initialTime, "25:00", "Initial time should be 25:00")

        // Pause
        viewModel.pauseSession()
        let pausedTime = viewModel.displayTime
        XCTAssertEqual(pausedTime, "25:00", "Time should be preserved after pause")

        // Resume
        viewModel.resumeSession()
        let resumedTime = viewModel.displayTime
        XCTAssertEqual(resumedTime, "25:00", "Time should be preserved after resume")

        XCTAssertTrue(viewModel.isPaused == false, "Should not be paused after resume")
    }

    func testUIIndicatesPausedState() {
        viewModel.startSession()

        // Running state
        XCTAssertFalse(viewModel.isPaused, "Should not be paused initially")
        XCTAssertTrue(viewModel.isRunning, "Should be running after start")

        // Paused state
        viewModel.pauseSession()
        XCTAssertTrue(viewModel.isPaused, "Should be paused after pause()")
        XCTAssertFalse(viewModel.isRunning, "Should not be running when paused")

        // Resumed state
        viewModel.resumeSession()
        XCTAssertFalse(viewModel.isPaused, "Should not be paused after resume()")
        XCTAssertTrue(viewModel.isRunning, "Should be running after resume")
    }

    func testCannotPauseWhenNotRunning() {
        // Cannot pause in idle state
        XCTAssertFalse(viewModel.canPause, "Should not be able to pause in idle state")

        // Cannot pause in paused state
        viewModel.startSession()
        viewModel.pauseSession()
        XCTAssertFalse(viewModel.canPause, "Should not be able to pause when already paused")
    }

    func testCannotResumeWhenNotPaused() {
        // Cannot resume in idle state
        XCTAssertFalse(viewModel.canResume, "Should not be able to resume in idle state")

        // Cannot resume when running
        viewModel.startSession()
        XCTAssertFalse(viewModel.canResume, "Should not be able to resume when running")
    }
}
