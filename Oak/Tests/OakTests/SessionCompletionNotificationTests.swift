import SwiftUI
import XCTest
@testable import Oak

@MainActor
private final class MockNotificationService: SessionCompletionNotifying {
    private(set) var sentNotifications: [Bool] = []

    func sendSessionCompletionNotification(isWorkSession: Bool) {
        sentNotifications.append(isWorkSession)
    }
}

@MainActor
private final class MockSessionCompletionSoundPlayer: SessionCompletionSoundPlaying {
    private(set) var playCallCount = 0

    func playCompletionSound() {
        playCallCount += 1
    }
}

@MainActor
internal final class SessionCompletionNotificationTests: XCTestCase {
    var viewModel: FocusSessionViewModel!
    var presetSettings: PresetSettingsStore!
    private var notificationService: MockNotificationService!
    private var completionSoundPlayer: MockSessionCompletionSoundPlayer!
    var presetSuiteName: String!

    override func setUp() async throws {
        let suiteName = "OakTests.SessionCompletion.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw NSError(domain: "SessionCompletionNotificationTests", code: 1)
        }
        userDefaults.removePersistentDomain(forName: suiteName)
        presetSuiteName = suiteName
        presetSettings = PresetSettingsStore(userDefaults: userDefaults)
        notificationService = MockNotificationService()
        completionSoundPlayer = MockSessionCompletionSoundPlayer()
        viewModel = FocusSessionViewModel(
            presetSettings: presetSettings,
            notificationService: notificationService,
            completionSoundPlayer: completionSoundPlayer
        )
    }

    override func tearDown() async throws {
        viewModel.cleanup()
        notificationService = nil
        completionSoundPlayer = nil
        if let presetSuiteName {
            UserDefaults(suiteName: presetSuiteName)?.removePersistentDomain(forName: presetSuiteName)
        }
    }

    func testViewModelHasNotificationService() {
        XCTAssertNotNil(viewModel.notificationService, "ViewModel should have notification service")
    }

    func testSessionCompletionTriggersNotificationFlag() {
        viewModel.startSession()
        XCTAssertFalse(viewModel.isSessionComplete, "Session should not be complete initially")

        viewModel.completeSession()

        XCTAssertTrue(viewModel.isSessionComplete, "Session should be marked complete")
        XCTAssertEqual(
            notificationService.sentNotifications,
            [true],
            "Work session completion should send notification"
        )
        XCTAssertEqual(completionSoundPlayer.playCallCount, 1, "Completion sound should play by default")
    }

    func testCompletionSoundSettingDefaultsToEnabled() {
        XCTAssertTrue(
            presetSettings.playSoundOnSessionCompletion,
            "Completion sound should be enabled by default"
        )
    }

    func testSessionCompletionDoesNotPlaySoundWhenOptedOut() {
        presetSettings.setPlaySoundOnSessionCompletion(false)
        viewModel.startSession()

        viewModel.completeSession()

        XCTAssertEqual(
            notificationService.sentNotifications,
            [true],
            "Notification should still be sent when opted out"
        )
        XCTAssertEqual(
            completionSoundPlayer.playCallCount,
            0,
            "Completion sound should not play when opted out"
        )
    }

    func testBreakCompletionSoundSettingDefaultsToEnabled() {
        XCTAssertTrue(
            presetSettings.playSoundOnBreakCompletion,
            "Break completion sound should be enabled by default"
        )
    }

    func testBreakCompletionPlaysSoundByDefault() {
        // Start and complete a work session
        viewModel.startSession()
        viewModel.completeSession()
        XCTAssertEqual(completionSoundPlayer.playCallCount, 1, "Work session completion should play sound")

        // Start and complete a break session
        viewModel.startNextSession() // This starts the break session
        viewModel.completeSession() // Complete the break session

        XCTAssertEqual(completionSoundPlayer.playCallCount, 2, "Break session completion should play sound by default")
    }

    func testBreakCompletionDoesNotPlaySoundWhenDisabled() {
        presetSettings.setPlaySoundOnBreakCompletion(false)

        // Start and complete a work session
        viewModel.startSession()
        viewModel.completeSession()
        XCTAssertEqual(completionSoundPlayer.playCallCount, 1, "Work session completion should play sound")

        // Start and complete a break session
        viewModel.startNextSession() // This starts the break session
        viewModel.completeSession() // Complete the break session

        XCTAssertEqual(
            completionSoundPlayer.playCallCount, 1,
            "Break session completion should not play sound when disabled"
        )
    }

    func testWorkSessionAlwaysPlaysSoundRegardlessOfBreakSetting() {
        presetSettings.setPlaySoundOnBreakCompletion(false)

        // Complete work session - should still play sound
        viewModel.startSession()
        viewModel.completeSession()

        XCTAssertEqual(completionSoundPlayer.playCallCount, 1, "Work session should always play sound")
    }

    func testPlaySoundOnBreakCompletionPersistence() {
        let suiteName = "OakTests.BreakSoundPersistence.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create UserDefaults")
            return
        }

        let store = PresetSettingsStore(userDefaults: userDefaults)
        XCTAssertTrue(store.playSoundOnBreakCompletion, "Should default to true")

        store.setPlaySoundOnBreakCompletion(false)
        XCTAssertFalse(store.playSoundOnBreakCompletion, "Should be false after setting")

        // Create a new store with same UserDefaults
        let reloadedStore = PresetSettingsStore(userDefaults: userDefaults)
        XCTAssertFalse(reloadedStore.playSoundOnBreakCompletion, "Should persist as false")

        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    func testResetToDefaultSetsPlaySoundOnBreakCompletionToTrue() {
        presetSettings.setPlaySoundOnBreakCompletion(false)
        XCTAssertFalse(presetSettings.playSoundOnBreakCompletion)

        presetSettings.resetToDefault()
        XCTAssertTrue(presetSettings.playSoundOnBreakCompletion, "Should reset to true")
    }
}
