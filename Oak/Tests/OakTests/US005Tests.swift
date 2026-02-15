import XCTest
@testable import Oak

@MainActor
internal final class US005Tests: XCTestCase {
    var viewModel: FocusSessionViewModel!
    var presetSettings: PresetSettingsStore!
    var presetSuiteName: String!

    override func setUp() async throws {
        let suiteName = "OakTests.US005.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw NSError(domain: "US005Tests", code: 1)
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

    func testSessionCompletionTriggersIsSessionComplete() {
        XCTAssertFalse(viewModel.isSessionComplete)

        viewModel.startSession()
        XCTAssertFalse(viewModel.isSessionComplete)

        viewModel.completeSession()
        XCTAssertTrue(viewModel.isSessionComplete)
    }

    func testCompletionSetsCompletedState() {
        viewModel.startSession()
        viewModel.completeSession()

        if case let .completed(isWorkSession) = viewModel.sessionState {
            XCTAssertTrue(isWorkSession, "Should be a completed work session")
        } else {
            XCTFail("Expected .completed state, got \(viewModel.sessionState)")
        }
    }

    func testWorkSessionCompletionIncrementsRounds() {
        XCTAssertEqual(viewModel.completedRounds, 0)

        viewModel.startSession()
        viewModel.completeSession()

        XCTAssertEqual(viewModel.completedRounds, 1)
    }

    func testBreakSessionCompletionDoesNotIncrementRounds() {
        viewModel.startSession()
        viewModel.completeSession()
        XCTAssertEqual(viewModel.completedRounds, 1)

        viewModel.startNextSession()
        viewModel.completeSession()

        XCTAssertEqual(viewModel.completedRounds, 1, "Break session should not increment completedRounds")
    }

    func testNextStateAfterWorkIsBreak() {
        viewModel.startSession()
        viewModel.completeSession()

        XCTAssertEqual(viewModel.currentSessionType, "Break")
    }

    func testNextStateAfterBreakIsFocus() {
        viewModel.startSession()
        viewModel.completeSession()

        viewModel.startNextSession()
        viewModel.completeSession()

        XCTAssertEqual(viewModel.currentSessionType, "Focus")
    }
}
