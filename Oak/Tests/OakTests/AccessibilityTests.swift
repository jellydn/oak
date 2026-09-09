import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class AccessibilityTests: XCTestCase {
    private var viewModel: FocusSessionViewModel!
    private var notificationService: NotificationService!
    private var sparkleUpdater: SparkleUpdater!
    private var suiteName: String!
    private var presetSettings: PresetSettingsStore!

    override func setUp() async throws {
        try await super.setUp()
        suiteName = "OakTests.AccessibilityTests.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw NSError(domain: "AccessibilityTests", code: 1)
        }
        notificationService = NotificationService()
        presetSettings = PresetSettingsStore(userDefaults: userDefaults)
        viewModel = FocusSessionViewModel(
            presetSettings: presetSettings,
            notificationService: notificationService
        )
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
        viewModel.startSession(using: .short)

        let view = NotchCompanionView(
            viewModel: viewModel,
            notificationService: notificationService,
            sparkleUpdater: sparkleUpdater
        )
        let sessionView = view.sessionView
        XCTAssertNotNil(sessionView, "Session view should exist when session is running")

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
        viewModel.startSession(using: .short)

        let view = NotchCompanionView(
            viewModel: viewModel,
            notificationService: notificationService,
            sparkleUpdater: sparkleUpdater
        )
        let countdown = view.countdownDisplay(
            mode: .number,
            size: 20,
            fontSize: 13
        )
        XCTAssertNotNil(countdown, "Countdown display should exist")

        viewModel.resetSession()
    }

    func testAccessibilityIdentifiersAreUnique() {
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
            "presetToggleButton",
            "themePicker",
            "settingsTabBar",
            "settingsTab_general",
            "settingsTab_sessions",
            "settingsTab_notifications",
            "settingsTab_shortcuts",
            "settingsTab_advanced"
        ]

        let uniqueIdentifiers = Set(identifiers)
        XCTAssertEqual(
            identifiers.count,
            uniqueIdentifiers.count,
            "All accessibility identifiers should be unique"
        )
    }

    internal func testSettingsWindowHeightFitsShortContent() {
        let height = SettingsWindowLayout.windowHeight(
            pageContentHeight: 180,
            navigationHeight: 52,
            screenHeight: 900
        )

        XCTAssertEqual(height, SettingsWindowLayout.minimumHeight)
    }

    internal func testSettingsWindowHeightTracksActiveTabContent() {
        let height = SettingsWindowLayout.windowHeight(
            pageContentHeight: 430,
            navigationHeight: 52,
            screenHeight: 900
        )

        XCTAssertEqual(height, 483)
    }

    internal func testSettingsWindowHeightBoundsLargeAccessibilityContent() {
        let height = SettingsWindowLayout.windowHeight(
            pageContentHeight: 1200,
            navigationHeight: 80,
            screenHeight: 700
        )

        XCTAssertEqual(height, 595)
        XCTAssertEqual(
            SettingsWindowLayout.pageViewportHeight(windowHeight: height, navigationHeight: 80),
            514
        )
    }

    internal func testSettingsTabNavigationHasStableLabelsAndMinimumWidth() {
        XCTAssertEqual(
            SettingsTab.allCases.map(\.title),
            ["General", "Sessions", "Notifications", "Shortcuts", "Advanced"]
        )
        XCTAssertEqual(
            SettingsTab.allCases.map(\.accessibilityIdentifier),
            [
                "settingsTab_general",
                "settingsTab_sessions",
                "settingsTab_notifications",
                "settingsTab_shortcuts",
                "settingsTab_advanced"
            ]
        )
        XCTAssertEqual(
            SettingsTab.allCases.map(\.symbolName),
            ["gearshape", "timer", "bell", "keyboard", "slider.horizontal.3"]
        )
        XCTAssertGreaterThanOrEqual(SettingsWindowLayout.minimumWidth, 560)
    }

    internal func testSettingsTabNavigationDividesConstrainedWidthsEqually() {
        XCTAssertEqual(SettingsTab.allCases.count, 5)
        XCTAssertEqual(SettingsWindowLayout.tabItemWidth(containerWidth: 400), 67.6, accuracy: 0.001)
        XCTAssertEqual(
            SettingsWindowLayout.tabItemWidth(containerWidth: SettingsWindowLayout.minimumWidth),
            99.6,
            accuracy: 0.001
        )
        XCTAssertEqual(
            SettingsWindowLayout.tabItemWidth(containerWidth: SettingsWindowLayout.idealWidth),
            107.6,
            accuracy: 0.001
        )
    }
}
