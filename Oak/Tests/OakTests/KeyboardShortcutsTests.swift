import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class KeyboardShortcutsTests: XCTestCase {
    var viewModel: FocusSessionViewModel!
    var presetSettings: PresetSettingsStore!
    var presetSuiteName: String!

    override func setUp() async throws {
        let suiteName = "OakTests.KeyboardShortcuts.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw NSError(domain: "KeyboardShortcutsTests", code: 1)
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

    func testSpaceKeyStartsSessionWhenIdle() {
        // Verify initial state
        XCTAssertTrue(viewModel.canStart)
        XCTAssertFalse(viewModel.isRunning)

        // Simulate Space key press - start session
        viewModel.startSession(using: .short)

        // Verify session started
        XCTAssertFalse(viewModel.canStart)
        XCTAssertTrue(viewModel.isRunning)
        XCTAssertTrue(viewModel.canPause)
    }

    func testSpaceKeyPausesSessionWhenRunning() {
        // Start a session
        viewModel.startSession()
        XCTAssertTrue(viewModel.isRunning)
        XCTAssertTrue(viewModel.canPause)

        // Simulate Space key press - pause session
        viewModel.pauseSession()

        // Verify session paused
        XCTAssertFalse(viewModel.isRunning)
        XCTAssertTrue(viewModel.isPaused)
        XCTAssertTrue(viewModel.canResume)
    }

    func testSpaceKeyResumesSessionWhenPaused() {
        // Start and pause a session
        viewModel.startSession()
        viewModel.pauseSession()
        XCTAssertTrue(viewModel.isPaused)
        XCTAssertTrue(viewModel.canResume)

        // Simulate Space key press - resume session
        viewModel.resumeSession()

        // Verify session resumed
        XCTAssertTrue(viewModel.isRunning)
        XCTAssertFalse(viewModel.isPaused)
        XCTAssertTrue(viewModel.canPause)
    }

    func testEscapeKeyResetsSessionWhenRunning() {
        // Start a session
        viewModel.startSession()
        XCTAssertTrue(viewModel.isRunning)
        XCTAssertFalse(viewModel.canStart)

        // Simulate Escape key press - reset session
        viewModel.resetSession()

        // Verify session reset to idle
        XCTAssertFalse(viewModel.isRunning)
        XCTAssertTrue(viewModel.canStart)
        if case .idle = viewModel.sessionState {
            // Success - session is idle
        } else {
            XCTFail("Expected session state to be idle")
        }
    }

    func testEscapeKeyResetsSessionWhenPaused() {
        // Start and pause a session
        viewModel.startSession()
        viewModel.pauseSession()
        XCTAssertTrue(viewModel.isPaused)

        // Simulate Escape key press - reset session
        viewModel.resetSession()

        // Verify session reset to idle
        XCTAssertFalse(viewModel.isPaused)
        XCTAssertTrue(viewModel.canStart)
        if case .idle = viewModel.sessionState {
            // Success - session is idle
        } else {
            XCTFail("Expected session state to be idle")
        }
    }

    func testReturnKeyStartsNextSessionWhenCompleted() {
        // Complete a session by setting state directly
        viewModel.startSession()
        viewModel.sessionState = .completed(isWorkSession: true)
        XCTAssertTrue(viewModel.canStartNext)

        // Simulate Return key press - start next session
        viewModel.startNextSession()

        // Verify next session started (should be a break)
        XCTAssertTrue(viewModel.isRunning)
        XCTAssertFalse(viewModel.canStartNext)
    }

    func testKeyboardShortcutsDoNotAffectIdleStateWithReset() {
        // Verify initial idle state
        XCTAssertTrue(viewModel.canStart)
        if case .idle = viewModel.sessionState {
            // Success - session is idle
        } else {
            XCTFail("Expected initial session state to be idle")
        }

        // Simulate Escape key press on idle state (should be no-op)
        viewModel.resetSession()

        // Verify still in idle state
        XCTAssertTrue(viewModel.canStart)
        if case .idle = viewModel.sessionState {
            // Success - session is still idle
        } else {
            XCTFail("Expected session state to remain idle")
        }
    }
}
