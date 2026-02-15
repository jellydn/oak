import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class LongBreakTests: XCTestCase {
    var viewModel: FocusSessionViewModel!
    var presetSettings: PresetSettingsStore!
    var presetSuiteName: String!

    override func setUp() async throws {
        let suiteName = "LongBreakTests.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw NSError(domain: "LongBreakTests", code: 1)
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

    // MARK: - Helper Methods

    private func completeFourWorkSessions() {
        for round in 1 ... 4 {
            if round == 1 {
                viewModel.startSession()
            } else {
                viewModel.startNextSession()
            }
            viewModel.completeSession()
            if round < 4 {
                viewModel.startNextSession()
                viewModel.completeSession()
            }
        }
    }

    func testLongBreakDurationsAreConfigured() {
        // Verify long break durations are defined
        XCTAssertEqual(
            presetSettings.longBreakDuration(for: .short),
            15 * 60,
            "Short preset long break should be 15 minutes"
        )
        XCTAssertEqual(
            presetSettings.longBreakDuration(for: .long),
            20 * 60,
            "Long preset long break should be 20 minutes"
        )
    }

    func testRoundCounterStartsAtZero() {
        // Verify initial state
        XCTAssertEqual(viewModel.completedRounds, 0, "Should start with 0 completed rounds")
    }

    func testRoundCounterIncrementsAfterWorkSession() {
        // Start and complete a work session
        viewModel.startSession()
        XCTAssertEqual(viewModel.completedRounds, 0, "Rounds should be 0 before completion")

        // Simulate work session completion
        viewModel.completeSession()
        XCTAssertEqual(viewModel.completedRounds, 1, "Rounds should increment to 1 after work completion")
    }

    func testRoundCounterDoesNotIncrementAfterBreakSession() {
        // Start and complete a work session first
        viewModel.startSession()
        viewModel.completeSession()
        XCTAssertEqual(viewModel.completedRounds, 1)

        // Start and complete a break session
        viewModel.startNextSession()
        XCTAssertEqual(viewModel.currentSessionType, "Break")
        viewModel.completeSession()

        // Rounds should still be 1
        XCTAssertEqual(viewModel.completedRounds, 1, "Rounds should not increment after break")
    }

    func testShortBreakUsedForFirstThreeRounds() {
        viewModel.selectedPreset = .short

        // Complete 3 work sessions and verify short breaks
        for round in 1 ... 3 {
            // Start work session
            if round == 1 {
                viewModel.startSession()
            } else {
                viewModel.startNextSession()
            }
            viewModel.completeSession()
            XCTAssertEqual(viewModel.completedRounds, round)

            // Start break and verify it's a short break
            viewModel.startNextSession()
            if case let .running(remaining, isWork) = viewModel.sessionState {
                XCTAssertFalse(isWork, "Should be a break session")
                XCTAssertEqual(
                    remaining,
                    presetSettings.breakDuration(for: .short),
                    "Should use short break duration for round \(round)"
                )
            } else {
                XCTFail("Should be in running state")
            }

            // Complete break
            viewModel.completeSession()
        }
    }

    func testLongBreakTriggeredAfterFourthRound() {
        viewModel.selectedPreset = .short

        // Complete 4 work sessions
        completeFourWorkSessions()

        // After 4th work session, verify UI shows "Long Break"
        XCTAssertEqual(viewModel.currentSessionType, "Long Break", "Should show 'Long Break' label after 4th round")

        // Next break should be long
        viewModel.startNextSession()
        XCTAssertEqual(viewModel.currentSessionType, "Long Break", "Should show 'Long Break' during long break session")

        if case let .running(remaining, isWork) = viewModel.sessionState {
            XCTAssertFalse(isWork, "Should be a break session")
            XCTAssertEqual(
                remaining,
                presetSettings.longBreakDuration(for: .short),
                "Should use long break duration after 4 rounds"
            )
        } else {
            XCTFail("Should be in running state")
        }
    }

    func testRoundCounterResetsAfterLongBreak() {
        viewModel.selectedPreset = .short

        // Complete 4 work sessions
        completeFourWorkSessions()

        XCTAssertEqual(viewModel.completedRounds, 4, "Should have 4 completed rounds")

        // Start long break
        viewModel.startNextSession()

        // Rounds should still be 4 while long break is in progress
        XCTAssertEqual(viewModel.completedRounds, 4, "Rounds should remain at 4 during long break")

        // Complete the long break
        viewModel.completeSession()

        // Rounds should be reset to 0 after long break completes
        XCTAssertEqual(viewModel.completedRounds, 0, "Rounds should reset to 0 after long break completes")
    }

    func testRoundsResetWhenLongBreakCancelled() {
        viewModel.selectedPreset = .short

        // Complete 4 work sessions to trigger long break
        completeFourWorkSessions()

        XCTAssertEqual(viewModel.completedRounds, 4)

        // Start long break but reset before completing
        viewModel.startNextSession()
        XCTAssertEqual(viewModel.currentSessionType, "Long Break")

        // Reset session (cancel long break)
        viewModel.resetSession()

        // Rounds should be reset to 0 (session reset always resets rounds)
        XCTAssertEqual(viewModel.completedRounds, 0, "Rounds should reset to 0 on session reset")

        // Starting a new session should restart the cycle
        viewModel.startSession()
        XCTAssertEqual(viewModel.completedRounds, 0)
    }

    func testRoundCounterResetsOnSessionReset() {
        // Complete a work session
        viewModel.startSession()
        viewModel.completeSession()
        XCTAssertEqual(viewModel.completedRounds, 1)

        // Reset session
        viewModel.resetSession()
        XCTAssertEqual(viewModel.completedRounds, 0, "Rounds should reset to 0 on session reset")
    }

    func testRoundCounterResetsOnNewSession() {
        // Complete a work session
        viewModel.startSession()
        viewModel.completeSession()
        XCTAssertEqual(viewModel.completedRounds, 1)

        // Start a new session from idle
        viewModel.resetSession()
        viewModel.startSession()
        XCTAssertEqual(viewModel.completedRounds, 0, "Rounds should reset to 0 on new session start")
    }

    func testDisplayTimeShowsLongBreakDurationAfterFourthRound() {
        viewModel.selectedPreset = .short

        // Complete 4 work sessions
        completeFourWorkSessions()

        // After 4th work session completion, display time should show long break duration
        XCTAssertEqual(viewModel.displayTime, "15:00", "Should display 15 minute long break time")
    }

    func testLongBreakWorksWithLongPreset() {
        viewModel.selectedPreset = .long

        // Complete 4 work sessions
        completeFourWorkSessions()

        // After 4th work session, next break should be long (20 minutes for long preset)
        XCTAssertEqual(viewModel.currentSessionType, "Long Break", "Should show 'Long Break' label")

        viewModel.startNextSession()
        XCTAssertEqual(viewModel.currentSessionType, "Long Break", "Should show 'Long Break' during long break")

        if case let .running(remaining, isWork) = viewModel.sessionState {
            XCTAssertFalse(isWork, "Should be a break session")
            XCTAssertEqual(
                remaining,
                presetSettings.longBreakDuration(for: .long),
                "Should use long break duration (20 min) for long preset"
            )
        } else {
            XCTFail("Should be in running state")
        }

        XCTAssertEqual(viewModel.displayTime, "20:00", "Should display 20 minute long break time for long preset")
    }

    func testCurrentSessionTypeDuringLongBreak() {
        viewModel.selectedPreset = .short

        // Complete 4 work sessions to reach long break
        completeFourWorkSessions()

        // Verify label shows "Long Break" in completed state
        XCTAssertEqual(viewModel.currentSessionType, "Long Break")

        // Start the long break and verify label during running state
        viewModel.startNextSession()
        XCTAssertEqual(viewModel.currentSessionType, "Long Break", "Should show 'Long Break' while running")

        // Pause and verify label during paused state
        viewModel.pauseSession()
        XCTAssertEqual(viewModel.currentSessionType, "Long Break", "Should show 'Long Break' while paused")

        // Resume and verify label
        viewModel.resumeSession()
        XCTAssertEqual(viewModel.currentSessionType, "Long Break", "Should show 'Long Break' after resume")
    }

    func testLongBreakTriggerUsesConfiguredRoundInterval() {
        presetSettings.setRoundsBeforeLongBreak(3)
        viewModel.selectedPreset = .short

        // Round 1
        viewModel.startSession()
        viewModel.completeSession()
        viewModel.startNextSession()
        viewModel.completeSession()

        // Round 2
        viewModel.startNextSession()
        viewModel.completeSession()
        XCTAssertEqual(viewModel.currentSessionType, "Break", "Should still be short break before configured interval")
        viewModel.startNextSession()
        viewModel.completeSession()

        // Round 3 should trigger long break
        viewModel.startNextSession()
        viewModel.completeSession()
        XCTAssertEqual(viewModel.currentSessionType, "Long Break", "Should trigger long break at configured interval")
    }

    func testLongBreakUsesConfiguredDuration() {
        presetSettings.setLongBreakMinutes(30, for: .short)
        viewModel.selectedPreset = .short

        completeFourWorkSessions()

        viewModel.startNextSession()

        if case let .running(remaining, isWork) = viewModel.sessionState {
            XCTAssertFalse(isWork, "Should be a break session")
            XCTAssertEqual(remaining, 30 * 60, "Should use configured long break duration")
        } else {
            XCTFail("Should be in running state")
        }
    }
}
