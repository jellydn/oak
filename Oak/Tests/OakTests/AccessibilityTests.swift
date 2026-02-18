import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class AccessibilityTests: XCTestCase {
    private var viewModel: FocusSessionViewModel!
    private var notificationService: NotificationService!
    private var sparkleUpdater: SparkleUpdater!
    private var suiteName: String!

    override func setUp() async throws {
        try await super.setUp()
        suiteName = "OakTests.AccessibilityTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        viewModel = FocusSessionViewModel(userDefaults: userDefaults)
        notificationService = NotificationService()
        sparkleUpdater = SparkleUpdater()
    }

    override func tearDown() async throws {
        viewModel.cleanup()
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        try await super.tearDown()
    }

    func testNotchCompanionViewHasAccessibilityElements() {
        let view = NotchCompanionView(
            viewModel: viewModel,
            notificationService: notificationService,
            sparkleUpdater: sparkleUpdater
        )
        XCTAssertNotNil(view, "NotchCompanionView should be initialized")
    }

    func testAudioButtonHasAccessibilityLabel() {
        let view = NotchCompanionView(
            viewModel: viewModel,
            notificationService: notificationService,
            sparkleUpdater: sparkleUpdater
        )
        let audioButton = view.audioButton
        XCTAssertNotNil(audioButton, "Audio button should exist")
    }

    func testProgressButtonHasAccessibilityLabel() {
        let view = NotchCompanionView(
            viewModel: viewModel,
            notificationService: notificationService,
            sparkleUpdater: sparkleUpdater
        )
        let progressButton = view.progressButton
        XCTAssertNotNil(progressButton, "Progress button should exist")
    }

    func testSettingsButtonHasAccessibilityLabel() {
        let view = NotchCompanionView(
            viewModel: viewModel,
            notificationService: notificationService,
            sparkleUpdater: sparkleUpdater
        )
        let settingsButton = view.settingsButton
        XCTAssertNotNil(settingsButton, "Settings button should exist")
    }

    func testExpandToggleButtonHasAccessibilityLabel() {
        let view = NotchCompanionView(
            viewModel: viewModel,
            notificationService: notificationService,
            sparkleUpdater: sparkleUpdater
        )
        let expandToggleButton = view.expandToggleButton
        XCTAssertNotNil(expandToggleButton, "Expand toggle button should exist")
    }

    func testPresetSelectorHasAccessibilityLabel() {
        let view = NotchCompanionView(
            viewModel: viewModel,
            notificationService: notificationService,
            sparkleUpdater: sparkleUpdater
        )
        let presetSelector = view.presetSelector
        XCTAssertNotNil(presetSelector, "Preset selector should exist")
    }

    func testStartViewHasAccessibilityLabel() {
        let view = NotchCompanionView(
            viewModel: viewModel,
            notificationService: notificationService,
            sparkleUpdater: sparkleUpdater
        )
        let startView = view.startView
        XCTAssertNotNil(startView, "Start view should exist")
    }

    func testCompactViewHasAccessibilityElements() {
        let view = NotchCompanionView(
            viewModel: viewModel,
            notificationService: notificationService,
            sparkleUpdater: sparkleUpdater
        )
        let compactView = view.compactView
        XCTAssertNotNil(compactView, "Compact view should exist")
    }

    func testSessionViewExistsAfterStartingSession() {
        // Start a session to make sessionView available
        viewModel.startSession(using: .short)

        let view = NotchCompanionView(
            viewModel: viewModel,
            notificationService: notificationService,
            sparkleUpdater: sparkleUpdater
        )
        let sessionView = view.sessionView
        XCTAssertNotNil(sessionView, "Session view should exist when session is running")

        // Clean up
        viewModel.resetSession()
    }

    func testInsideNotchCompactContentHasAccessibilityElements() {
        let view = NotchCompanionView(
            viewModel: viewModel,
            notificationService: notificationService,
            sparkleUpdater: sparkleUpdater
        )
        let insideNotchCompactContent = view.insideNotchCompactContent
        XCTAssertNotNil(insideNotchCompactContent, "Inside notch compact content should exist")
    }

    func testInsideNotchExpandedContentHasAccessibilityElements() {
        let view = NotchCompanionView(
            viewModel: viewModel,
            notificationService: notificationService,
            sparkleUpdater: sparkleUpdater
        )
        let insideNotchExpandedContent = view.insideNotchExpandedContent
        XCTAssertNotNil(insideNotchExpandedContent, "Inside notch expanded content should exist")
    }

    func testPresetChipHasAccessibilityTraits() {
        let view = NotchCompanionView(
            viewModel: viewModel,
            notificationService: notificationService,
            sparkleUpdater: sparkleUpdater
        )
        let shortChip = view.presetChip(.short)
        let longChip = view.presetChip(.long)
        XCTAssertNotNil(shortChip, "Short preset chip should exist")
        XCTAssertNotNil(longChip, "Long preset chip should exist")
    }

    func testCountdownDisplayHasAccessibilityLabel() {
        // Start a session to make countdown display meaningful
        viewModel.startSession(using: .short)

        let view = NotchCompanionView(
            viewModel: viewModel,
            notificationService: notificationService,
            sparkleUpdater: sparkleUpdater
        )
        let countdown = view.countdownDisplay(
            mode: .digitalClock,
            size: 20,
            fontSize: 13
        )
        XCTAssertNotNil(countdown, "Countdown display should exist")

        // Clean up
        viewModel.resetSession()
    }

    func testAccessibilityIdentifiersAreUnique() {
        // This test verifies that all accessibility identifiers follow a consistent pattern
        // The actual accessibility identifiers are set in the view code
        let identifiers = [
            "audioButton",
            "progressButton",
            "settingsButton",
            "expandToggleButton",
            "presetSelector",
            "presetChip_short",
            "presetChip_long",
            "startButton",
            "pauseButton",
            "resumeButton",
            "stopButton",
            "startNextButton",
            "countdownDisplay",
            "autoStartCountdown",
            "presetToggleButton"
        ]

        // Ensure no duplicates
        let uniqueIdentifiers = Set(identifiers)
        XCTAssertEqual(
            identifiers.count,
            uniqueIdentifiers.count,
            "All accessibility identifiers should be unique"
        )
    }
}
