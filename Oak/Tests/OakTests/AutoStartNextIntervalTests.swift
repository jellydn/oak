import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class AutoStartNextIntervalTests: XCTestCase {
    var viewModel: FocusSessionViewModel!
    var presetSettings: PresetSettingsStore!
    var presetSuiteName: String!
    var userDefaults: UserDefaults!

    override func setUp() async throws {
        let suiteName = "AutoStartNextIntervalTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw NSError(domain: "AutoStartNextIntervalTests", code: 1)
        }
        defaults.removePersistentDomain(forName: suiteName)
        presetSuiteName = suiteName
        userDefaults = defaults
        presetSettings = PresetSettingsStore(userDefaults: defaults)
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
        presetSettings = nil
        userDefaults = nil
        viewModel = nil
    }

    // MARK: - PresetSettingsStore Tests

    func testAutoStartNextIntervalDefaultsToFalse() {
        XCTAssertFalse(presetSettings.autoStartNextInterval, "autoStartNextInterval should default to false")
    }

    func testSetAutoStartNextIntervalToTrue() {
        presetSettings.setAutoStartNextInterval(true)
        XCTAssertTrue(presetSettings.autoStartNextInterval, "autoStartNextInterval should be true after setting")
    }

    func testSetAutoStartNextIntervalToFalse() {
        presetSettings.setAutoStartNextInterval(true)
        presetSettings.setAutoStartNextInterval(false)
        XCTAssertFalse(presetSettings.autoStartNextInterval, "autoStartNextInterval should be false after setting")
    }

    func testSetAutoStartNextIntervalToSameValueDoesNotTriggerChange() {
        presetSettings.setAutoStartNextInterval(false)
        let initial = presetSettings.autoStartNextInterval

        presetSettings.setAutoStartNextInterval(false)
        let final = presetSettings.autoStartNextInterval

        XCTAssertEqual(initial, final, "Setting to same value should not trigger change")
    }

    func testAutoStartNextIntervalPersistsToUserDefaults() {
        presetSettings.setAutoStartNextInterval(true)

        let persistedValue = userDefaults.bool(forKey: "session.autoStartNextInterval")
        XCTAssertTrue(persistedValue, "autoStartNextInterval value should persist to UserDefaults")
    }

    func testAutoStartNextIntervalLoadedFromUserDefaults() {
        userDefaults.set(true, forKey: "session.autoStartNextInterval")

        let newSettings = PresetSettingsStore(userDefaults: userDefaults)
        XCTAssertTrue(newSettings.autoStartNextInterval, "autoStartNextInterval should load from UserDefaults")
    }

    func testAutoStartNextIntervalFalseLoadedFromUserDefaults() {
        userDefaults.set(false, forKey: "session.autoStartNextInterval")

        let newSettings = PresetSettingsStore(userDefaults: userDefaults)
        XCTAssertFalse(
            newSettings.autoStartNextInterval,
            "autoStartNextInterval false should load from UserDefaults"
        )
    }

    func testResetToDefaultSetsAutoStartNextIntervalToFalse() {
        presetSettings.setAutoStartNextInterval(true)
        XCTAssertTrue(presetSettings.autoStartNextInterval, "Precondition: autoStartNextInterval should be true")

        presetSettings.resetToDefault()

        XCTAssertFalse(
            presetSettings.autoStartNextInterval,
            "resetToDefault should set autoStartNextInterval to false"
        )
    }

    func testResetToDefaultPersistsAutoStartNextIntervalToUserDefaults() {
        presetSettings.setAutoStartNextInterval(true)
        presetSettings.resetToDefault()

        let persistedValue = userDefaults.bool(forKey: "session.autoStartNextInterval")
        XCTAssertFalse(persistedValue, "resetToDefault should persist false to UserDefaults")
    }

    func testAutoStartNextIntervalIsPublished() async {
        let expectation = expectation(description: "Published value changed")
        var receivedValue: Bool?

        let cancellable = presetSettings.$autoStartNextInterval
            .dropFirst() // Skip initial value
            .sink { value in
                receivedValue = value
                expectation.fulfill()
            }

        presetSettings.setAutoStartNextInterval(true)

        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertEqual(receivedValue, true, "Published property should emit new value")
        cancellable.cancel()
    }

    // MARK: - FocusSessionViewModel Auto-Start Tests

    func testAutoStartCountdownStartsAtZero() {
        XCTAssertEqual(viewModel.autoStartCountdown, 0, "autoStartCountdown should start at 0")
    }

    func testAutoStartCountdownDoesNotStartWhenDisabled() async {
        presetSettings.setAutoStartNextInterval(false)

        viewModel.startSession()
        viewModel.completeSession()

        // Wait for animation to complete (1.5 seconds)
        try? await Task.sleep(nanoseconds: 2000000000)

        XCTAssertEqual(viewModel.autoStartCountdown, 0, "Countdown should not start when auto-start is disabled")
    }

    func testAutoStartCountdownStartsWhenEnabled() async {
        presetSettings.setAutoStartNextInterval(true)

        viewModel.startSession()
        viewModel.completeSession()

        // Wait for animation to complete (1.5 seconds)
        try? await Task.sleep(nanoseconds: 2000000000)

        XCTAssertGreaterThan(viewModel.autoStartCountdown, 0, "Countdown should start when auto-start is enabled")
        XCTAssertLessThanOrEqual(viewModel.autoStartCountdown, 10, "Countdown should not exceed 10 seconds")
    }

    func testAutoStartCountdownDecrementsOverTime() async {
        presetSettings.setAutoStartNextInterval(true)

        viewModel.startSession()
        viewModel.completeSession()

        // Wait for animation to complete
        try? await Task.sleep(nanoseconds: 2000000000)

        let initialCount = viewModel.autoStartCountdown
        XCTAssertGreaterThan(initialCount, 0, "Initial countdown should be greater than 0")

        // Wait for 2 more seconds
        try? await Task.sleep(nanoseconds: 2000000000)

        let laterCount = viewModel.autoStartCountdown
        XCTAssertLessThan(laterCount, initialCount, "Countdown should decrement over time")
    }

    func testAutoStartCountdownResetsOnReset() async {
        presetSettings.setAutoStartNextInterval(true)

        viewModel.startSession()
        viewModel.completeSession()

        // Wait for animation to complete
        try? await Task.sleep(nanoseconds: 2000000000)

        XCTAssertGreaterThan(viewModel.autoStartCountdown, 0, "Countdown should be active")

        viewModel.resetSession()

        XCTAssertEqual(viewModel.autoStartCountdown, 0, "Countdown should reset to 0 on session reset")
    }

    func testManualStartNextCancelsAutoStartCountdown() async {
        presetSettings.setAutoStartNextInterval(true)

        viewModel.startSession()
        viewModel.completeSession()

        // Wait for animation to complete
        try? await Task.sleep(nanoseconds: 2000000000)

        XCTAssertGreaterThan(viewModel.autoStartCountdown, 0, "Countdown should be active")

        // Manually start next session
        viewModel.startNextSession()

        XCTAssertEqual(viewModel.autoStartCountdown, 0, "Countdown should be cancelled on manual start")
        XCTAssertTrue(viewModel.isRunning, "Session should be running after manual start")
    }

    func testAutoStartCountdownResetsAfterCompletion() async {
        presetSettings.setAutoStartNextInterval(true)

        viewModel.startSession()
        viewModel.completeSession()

        // Wait for animation and countdown to complete
        try? await Task.sleep(nanoseconds: 13000000000) // 13 seconds to ensure countdown completes

        XCTAssertEqual(viewModel.autoStartCountdown, 0, "Countdown should reset to 0 after auto-start")
        XCTAssertTrue(viewModel.isRunning, "Session should be running after auto-start")
    }

    func testAutoStartOnlyWorksInCompletedState() async {
        presetSettings.setAutoStartNextInterval(true)

        // Test in idle state
        XCTAssertEqual(viewModel.autoStartCountdown, 0, "No countdown in idle state")

        // Start a session (running state)
        viewModel.startSession()
        XCTAssertEqual(viewModel.autoStartCountdown, 0, "No countdown in running state")

        // Pause session (paused state)
        viewModel.pauseSession()
        XCTAssertEqual(viewModel.autoStartCountdown, 0, "No countdown in paused state")

        // Resume and complete
        viewModel.resumeSession()
        viewModel.completeSession()

        // Wait for animation to complete
        try? await Task.sleep(nanoseconds: 2000000000)

        // Now countdown should start
        XCTAssertGreaterThan(viewModel.autoStartCountdown, 0, "Countdown should start in completed state")
    }

    func testAutoStartCountdownIsPublished() async {
        presetSettings.setAutoStartNextInterval(true)

        let expectation = expectation(description: "Countdown value changed")
        var receivedValue: Int?

        let cancellable = viewModel.$autoStartCountdown
            .dropFirst() // Skip initial value
            .sink { value in
                if value > 0 {
                    receivedValue = value
                    expectation.fulfill()
                }
            }

        viewModel.startSession()
        viewModel.completeSession()

        await fulfillment(of: [expectation], timeout: 3.0)

        XCTAssertNotNil(receivedValue, "Published property should emit new value")
        XCTAssertGreaterThan(receivedValue!, 0, "Countdown value should be greater than 0")
        cancellable.cancel()
    }
}
