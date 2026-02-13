import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class LongBreakTests: XCTestCase {
    var viewModel: FocusSessionViewModel!
    var presetSettings: PresetSettingsStore!
    var presetSuiteName: String!

    override func setUp() async throws {
        let suiteName = "OakTests.LongBreak.\(UUID().uuidString)"
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

    func testLongBreakDurationsAreConfigured() {
        // Verify long break durations are defined
        XCTAssertEqual(Preset.short.longBreakDuration, 15 * 60, "Short preset long break should be 15 minutes")
        XCTAssertEqual(Preset.long.longBreakDuration, 20 * 60, "Long preset long break should be 20 minutes")
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
        viewModel.completeSessionForTesting()
        XCTAssertEqual(viewModel.completedRounds, 1, "Rounds should increment to 1 after work completion")
    }

    func testRoundCounterDoesNotIncrementAfterBreakSession() {
        // Start and complete a work session first
        viewModel.startSession()
        viewModel.completeSessionForTesting()
        XCTAssertEqual(viewModel.completedRounds, 1)

        // Start and complete a break session
        viewModel.startNextSession()
        XCTAssertEqual(viewModel.currentSessionType, "Break")
        viewModel.completeSessionForTesting()

        // Rounds should still be 1
        XCTAssertEqual(viewModel.completedRounds, 1, "Rounds should not increment after break")
    }

    func testShortBreakUsedForFirstThreeRounds() {
        viewModel.selectedPreset = .short

        // Complete 3 work sessions and verify short breaks
        for round in 1...3 {
            // Start work session
            if round == 1 {
                viewModel.startSession()
            } else {
                viewModel.startNextSession()
            }
            viewModel.completeSessionForTesting()
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
            viewModel.completeSessionForTesting()
        }
    }

    func testLongBreakTriggeredAfterFourthRound() {
        viewModel.selectedPreset = .short

        // Complete 4 work sessions
        for round in 1...4 {
            if round == 1 {
                viewModel.startSession()
            } else {
                viewModel.startNextSession()
            }
            viewModel.completeSessionForTesting()
            XCTAssertEqual(viewModel.completedRounds, round)

            // Complete break if not the 4th round
            if round < 4 {
                viewModel.startNextSession()
                viewModel.completeSessionForTesting()
            }
        }

        // After 4th work session, next break should be long
        viewModel.startNextSession()
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
        for _ in 1...4 {
            viewModel.startSession()
            viewModel.completeSessionForTesting()
            if viewModel.completedRounds < 4 {
                viewModel.startNextSession()
                viewModel.completeSessionForTesting()
            }
        }

        XCTAssertEqual(viewModel.completedRounds, 4, "Should have 4 completed rounds")

        // Start long break
        viewModel.startNextSession()

        // Rounds should be reset to 0 after starting long break
        XCTAssertEqual(viewModel.completedRounds, 0, "Rounds should reset to 0 after long break starts")
    }

    func testRoundCounterResetsOnSessionReset() {
        // Complete a work session
        viewModel.startSession()
        viewModel.completeSessionForTesting()
        XCTAssertEqual(viewModel.completedRounds, 1)

        // Reset session
        viewModel.resetSession()
        XCTAssertEqual(viewModel.completedRounds, 0, "Rounds should reset to 0 on session reset")
    }

    func testRoundCounterResetsOnNewSession() {
        // Complete a work session
        viewModel.startSession()
        viewModel.completeSessionForTesting()
        XCTAssertEqual(viewModel.completedRounds, 1)

        // Start a new session from idle
        viewModel.resetSession()
        viewModel.startSession()
        XCTAssertEqual(viewModel.completedRounds, 0, "Rounds should reset to 0 on new session start")
    }

    func testDisplayTimeShowsLongBreakDurationAfterFourthRound() {
        viewModel.selectedPreset = .short

        // Complete 4 work sessions
        for round in 1...4 {
            if round == 1 {
                viewModel.startSession()
            } else {
                viewModel.startNextSession()
            }
            viewModel.completeSessionForTesting()

            // Complete break after rounds 1-3
            if round < 4 {
                viewModel.startNextSession()
                viewModel.completeSessionForTesting()
            }
        }

        // After 4th work session completion, display time should show long break duration
        XCTAssertEqual(viewModel.displayTime, "15:00", "Should display 15 minute long break time")
    }

    func testLongBreakWorksWithLongPreset() {
        viewModel.selectedPreset = .long

        // Complete 4 work sessions
        for round in 1...4 {
            if round == 1 {
                viewModel.startSession()
            } else {
                viewModel.startNextSession()
            }
            viewModel.completeSessionForTesting()

            if round < 4 {
                viewModel.startNextSession()
                viewModel.completeSessionForTesting()
            }
        }

        // After 4th work session, next break should be long (20 minutes for long preset)
        viewModel.startNextSession()
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
}
