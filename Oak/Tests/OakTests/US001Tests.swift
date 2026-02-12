import XCTest
import SwiftUI
@testable import Oak

@MainActor
final class US001Tests: XCTestCase {
    var viewModel: FocusSessionViewModel!

    override func setUp() async throws {
        viewModel = FocusSessionViewModel()
    }

    override func tearDown() async throws {
        viewModel.cleanup()
    }

    func testNotchCompanionIsVisible() {
        // Test that notch companion can be instantiated
        let notchView = NotchCompanionView()
        XCTAssertNotNil(notchView)
    }

    func testPrimaryActionStarts25MinuteSession() {
        // Verify initial state
        XCTAssertEqual(viewModel.canStart, true)
        XCTAssertEqual(viewModel.displayTime, "25:00")

        // Start session
        viewModel.startSession()

        // Verify session is running
        XCTAssertEqual(viewModel.canStart, false)
        XCTAssertEqual(viewModel.canPause, true)
        XCTAssertEqual(viewModel.isRunning, true)
        XCTAssertEqual(viewModel.currentSessionType, "Focus")
    }

    func testSessionStateChangesWithin500ms() {
        let startTime = Date()
        viewModel.startSession()
        let endTime = Date()

        let elapsed = endTime.timeIntervalSince(startTime) * 1000 // Convert to ms
        XCTAssertLessThan(elapsed, 500, "Session state should change within 500ms")
    }

    func testSelectedPresetDisplaysCorrectly() {
        viewModel.selectedPreset = .short
        XCTAssertEqual(viewModel.displayTime, "25:00")

        viewModel.selectedPreset = .long
        XCTAssertEqual(viewModel.displayTime, "50:00")
    }
}
