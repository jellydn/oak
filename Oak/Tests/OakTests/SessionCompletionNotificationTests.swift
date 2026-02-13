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

        viewModel.completeSessionForTesting()

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

        viewModel.completeSessionForTesting()

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
}
