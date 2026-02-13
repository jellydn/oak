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
internal final class SessionCompletionNotificationTests: XCTestCase {
    var viewModel: FocusSessionViewModel!
    var presetSettings: PresetSettingsStore!
    private var notificationService: MockNotificationService!
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
        viewModel = FocusSessionViewModel(
            presetSettings: presetSettings,
            notificationService: notificationService
        )
    }

    override func tearDown() async throws {
        viewModel.cleanup()
        notificationService = nil
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
    }
}
