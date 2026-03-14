import XCTest
@testable import Oak

@MainActor
internal extension NotchCompanionViewTests {
    // MARK: - Session State Driven ViewModel Properties

    func testViewModelCanStartInIdleState() {
        XCTAssertTrue(viewModel.canStart, "ViewModel should canStart in idle state")
        XCTAssertFalse(viewModel.canPause)
        XCTAssertFalse(viewModel.canResume)
        XCTAssertFalse(viewModel.canStartNext)
    }

    func testViewModelCanPauseWhenRunning() {
        viewModel.startSession(using: .short)
        XCTAssertFalse(viewModel.canStart)
        XCTAssertTrue(viewModel.canPause, "ViewModel should canPause when running")
        XCTAssertFalse(viewModel.canResume)
        XCTAssertFalse(viewModel.canStartNext)
        viewModel.resetSession()
    }

    func testViewModelCanResumeWhenPaused() {
        viewModel.startSession(using: .short)
        viewModel.pauseSession()
        XCTAssertFalse(viewModel.canStart)
        XCTAssertFalse(viewModel.canPause)
        XCTAssertTrue(viewModel.canResume, "ViewModel should canResume when paused")
        XCTAssertFalse(viewModel.canStartNext)
        viewModel.resetSession()
    }

    func testViewModelCanStartNextAfterCompletion() {
        viewModel.startSession(using: .short)
        viewModel.completeSession()
        XCTAssertFalse(viewModel.canStart)
        XCTAssertFalse(viewModel.canPause)
        XCTAssertFalse(viewModel.canResume)
        XCTAssertTrue(viewModel.canStartNext, "ViewModel should canStartNext after completion")
        viewModel.resetSession()
    }

    func testViewModelResetsToIdleStateAfterReset() {
        viewModel.startSession(using: .short)
        viewModel.resetSession()
        XCTAssertTrue(viewModel.canStart, "ViewModel should return to canStart state after reset")
        XCTAssertFalse(viewModel.canPause)
        XCTAssertFalse(viewModel.canResume)
        XCTAssertFalse(viewModel.canStartNext)
    }

    func testViewModelStateTransitionIdleToRunningToPausedToIdle() {
        XCTAssertTrue(viewModel.canStart, "Should be idle initially")
        viewModel.startSession(using: .short)
        XCTAssertTrue(viewModel.canPause, "Should be running after start")
        viewModel.pauseSession()
        XCTAssertTrue(viewModel.canResume, "Should be paused after pause")
        viewModel.resumeSession()
        XCTAssertTrue(viewModel.canPause, "Should be running again after resume")
        viewModel.resetSession()
        XCTAssertTrue(viewModel.canStart, "Should be idle after reset")
    }

    // MARK: - Countdown Display

    /// Verifies that progressPercentage is in [0, 1] once a session is running, driving circle ring mode.
    func testCountdownDisplayProgressPercentageInRangeWhenRunning() {
        viewModel.startSession(using: .short)
        XCTAssertGreaterThanOrEqual(viewModel.progressPercentage, 0.0)
        XCTAssertLessThanOrEqual(viewModel.progressPercentage, 1.0)
        viewModel.resetSession()
    }

    /// Verifies that isPaused is false while running, true while paused — drives colour in countdown display.
    func testCountdownDisplayIsPausedStateMatchesSessionState() {
        viewModel.startSession(using: .short)
        XCTAssertFalse(viewModel.isPaused, "isPaused should be false while session is running")
        viewModel.pauseSession()
        XCTAssertTrue(viewModel.isPaused, "isPaused should be true while session is paused")
        viewModel.resetSession()
    }

    /// Verifies that displayTime is non-empty once a session is running (drives the number countdown display).
    func testCountdownDisplayTimeIsNonEmptyWhenRunning() {
        viewModel.startSession(using: .short)
        XCTAssertFalse(viewModel.displayTime.isEmpty, "displayTime should be non-empty when running")
        viewModel.resetSession()
    }

    // MARK: - Completion Animation

    func testViewModelIsSessionCompleteDefaultsFalse() {
        XCTAssertFalse(viewModel.isSessionComplete, "isSessionComplete should default to false")
    }

    func testViewModelIsSessionCompleteTrueAfterComplete() {
        viewModel.startSession(using: .short)
        viewModel.completeSession()
        XCTAssertTrue(viewModel.isSessionComplete, "isSessionComplete should be true after completeSession")
        viewModel.resetSession()
    }

    func testViewModelIsSessionCompleteResetAfterReset() {
        viewModel.startSession(using: .short)
        viewModel.completeSession()
        viewModel.resetSession()
        XCTAssertFalse(viewModel.isSessionComplete, "isSessionComplete should be false after reset")
    }

    func testSessionCompletionSetsWorkSessionStateForConfettiTrigger() {
        viewModel.startSession(using: .short)
        XCTAssertTrue(viewModel.isRunning, "Precondition: session must be running")
        viewModel.completeSession()
        if case .completed(let isWorkSession) = viewModel.sessionState {
            XCTAssertTrue(isWorkSession, "Completing a work session should set isWorkSession=true in state")
        } else {
            XCTFail("Session state should be .completed after completeSession")
        }
        viewModel.resetSession()
    }
}
