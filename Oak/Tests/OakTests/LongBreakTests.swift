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
        viewModel = FocusSessionViewModel(
            presetSettings: presetSettings,
            notificationService: NotificationService()
        )
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
        XCTAssertEqual(
            presetSettings.longBreakDuration(for: .short),
            15 * 60
        )
        XCTAssertEqual(
            presetSettings.longBreakDuration(for: .long),
            20 * 60
        )
    }

    func testRoundCounterStartsAtZero() {
        XCTAssertEqual(viewModel.completedRounds, 0)
    }

    func testRoundCounterIncrementsAfterWorkSession() {
        viewModel.startSession()
        XCTAssertEqual(viewModel.completedRounds, 0)

        viewModel.completeSession()
        XCTAssertEqual(viewModel.completedRounds, 1)
    }

    func testRoundCounterDoesNotIncrementAfterBreakSession() {
        viewModel.startSession()
        viewModel.completeSession()
        XCTAssertEqual(viewModel.completedRounds, 1)

        viewModel.startNextSession()
        XCTAssertEqual(viewModel.currentSessionType, "Break")
        viewModel.completeSession()

        XCTAssertEqual(viewModel.completedRounds, 1)
    }

    func testShortBreakUsedForFirstThreeRounds() {
        viewModel.selectedPreset = .short

        for round in 1 ... 3 {
            if round == 1 {
                viewModel.startSession()
            } else {
                viewModel.startNextSession()
            }
            viewModel.completeSession()
            XCTAssertEqual(viewModel.completedRounds, round)

            viewModel.startNextSession()
            if case let .running(remaining, isWork) = viewModel.sessionState {
                XCTAssertFalse(isWork)
                XCTAssertEqual(
                    remaining,
                    presetSettings.breakDuration(for: .short)
                )
            } else {
                XCTFail("Should be in running state")
            }

            viewModel.completeSession()
        }
    }

    func testLongBreakTriggeredAfterFourthRound() {
        viewModel.selectedPreset = .short

        completeFourWorkSessions()

        XCTAssertEqual(viewModel.currentSessionType, "Long Break")

        viewModel.startNextSession()
        XCTAssertEqual(viewModel.currentSessionType, "Long Break")

        if case let .running(remaining, isWork) = viewModel.sessionState {
            XCTAssertFalse(isWork)
            XCTAssertEqual(
                remaining,
                presetSettings.longBreakDuration(for: .short)
            )
        } else {
            XCTFail("Should be in running state")
        }
    }

    func testRoundCounterResetsAfterLongBreak() {
        viewModel.selectedPreset = .short

        completeFourWorkSessions()

        XCTAssertEqual(viewModel.completedRounds, 4)

        viewModel.startNextSession()

        XCTAssertEqual(viewModel.completedRounds, 4)

        viewModel.completeSession()

        XCTAssertEqual(viewModel.completedRounds, 0)
    }

    func testRoundCounterResetsAfterLongBreakWithAutoStart() {
        presetSettings.setAutoStartNextInterval(true)
        viewModel.selectedPreset = .short

        completeFourWorkSessions()

        XCTAssertEqual(viewModel.completedRounds, 4)

        viewModel.startNextSession(isAutoStart: true)

        XCTAssertEqual(viewModel.completedRounds, 4)

        viewModel.completeSession()

        XCTAssertEqual(viewModel.completedRounds, 0)

        viewModel.startNextSession(isAutoStart: true)

        XCTAssertEqual(viewModel.currentSessionType, "Focus")
        XCTAssertEqual(viewModel.completedRounds, 0)
    }

    func testRoundsResetWhenLongBreakCancelled() {
        viewModel.selectedPreset = .short

        completeFourWorkSessions()

        XCTAssertEqual(viewModel.completedRounds, 4)

        viewModel.startNextSession()
        XCTAssertEqual(viewModel.currentSessionType, "Long Break")

        viewModel.resetSession()

        XCTAssertEqual(viewModel.completedRounds, 0)

        viewModel.startSession()
        XCTAssertEqual(viewModel.completedRounds, 0)
    }

    func testRoundCounterResetsOnSessionReset() {
        viewModel.startSession()
        viewModel.completeSession()
        XCTAssertEqual(viewModel.completedRounds, 1)

        viewModel.resetSession()
        XCTAssertEqual(viewModel.completedRounds, 0)
    }

    func testRoundCounterResetsOnNewSession() {
        viewModel.startSession()
        viewModel.completeSession()
        XCTAssertEqual(viewModel.completedRounds, 1)

        viewModel.resetSession()
        viewModel.startSession()
        XCTAssertEqual(viewModel.completedRounds, 0)
    }

    func testDisplayTimeShowsLongBreakDurationAfterFourthRound() {
        viewModel.selectedPreset = .short

        completeFourWorkSessions()

        XCTAssertEqual(viewModel.displayTime, "15:00")
    }

    func testLongBreakWorksWithLongPreset() {
        viewModel.selectedPreset = .long

        completeFourWorkSessions()

        XCTAssertEqual(viewModel.currentSessionType, "Long Break")

        viewModel.startNextSession()
        XCTAssertEqual(viewModel.currentSessionType, "Long Break")

        if case let .running(remaining, isWork) = viewModel.sessionState {
            XCTAssertFalse(isWork)
            XCTAssertEqual(
                remaining,
                presetSettings.longBreakDuration(for: .long)
            )
        } else {
            XCTFail("Should be in running state")
        }

        XCTAssertEqual(viewModel.displayTime, "20:00")
    }

    func testCurrentSessionTypeDuringLongBreak() {
        viewModel.selectedPreset = .short

        completeFourWorkSessions()

        XCTAssertEqual(viewModel.currentSessionType, "Long Break")

        viewModel.startNextSession()
        XCTAssertEqual(viewModel.currentSessionType, "Long Break")

        viewModel.pauseSession()
        XCTAssertEqual(viewModel.currentSessionType, "Long Break")

        viewModel.resumeSession()
        XCTAssertEqual(viewModel.currentSessionType, "Long Break")
    }

    func testLongBreakTriggerUsesConfiguredRoundInterval() {
        presetSettings.setRoundsBeforeLongBreak(3)
        viewModel.selectedPreset = .short

        viewModel.startSession()
        viewModel.completeSession()
        viewModel.startNextSession()
        viewModel.completeSession()

        viewModel.startNextSession()
        viewModel.completeSession()
        XCTAssertEqual(viewModel.currentSessionType, "Break")
        viewModel.startNextSession()
        viewModel.completeSession()

        viewModel.startNextSession()
        viewModel.completeSession()
        XCTAssertEqual(viewModel.currentSessionType, "Long Break")
    }

    func testLongBreakUsesConfiguredDuration() {
        presetSettings.setLongBreakMinutes(30, for: .short)
        viewModel.selectedPreset = .short

        completeFourWorkSessions()

        viewModel.startNextSession()

        if case let .running(remaining, isWork) = viewModel.sessionState {
            XCTAssertFalse(isWork)
            XCTAssertEqual(remaining, 30 * 60)
        } else {
            XCTFail("Should be in running state")
        }
    }
}
