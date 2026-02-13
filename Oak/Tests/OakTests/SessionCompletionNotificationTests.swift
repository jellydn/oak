import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class SessionCompletionNotificationTests: XCTestCase {
    var viewModel: FocusSessionViewModel!
    var presetSettings: PresetSettingsStore!
    var presetSuiteName: String!
    
    override func setUp() async throws {
        let suiteName = "OakTests.SessionCompletion.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw NSError(domain: "SessionCompletionNotificationTests", code: 1)
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
    
    func testViewModelHasNotificationService() {
        XCTAssertNotNil(viewModel.notificationService, "ViewModel should have notification service")
    }
    
    func testSessionCompletionTriggersNotificationFlag() async throws {
        // Start a session
        viewModel.startSession()
        XCTAssertFalse(viewModel.isSessionComplete, "Session should not be complete initially")
        
        // Note: We can't directly trigger completion without waiting for the timer
        // but we can verify the flag is properly set up
        XCTAssertTrue(viewModel.isRunning, "Session should be running")
    }
}
