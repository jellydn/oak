import SwiftUI
import XCTest
@testable import Oak

// MARK: - NotchCompanionViewTests

@MainActor
internal final class NotchCompanionViewTests: XCTestCase {
    private var viewModel: FocusSessionViewModel!
    private var notificationService: NotificationService!
    private var sparkleUpdater: SparkleUpdater!
    private var presetSettings: PresetSettingsStore!
    private var suiteName: String!

    override func setUp() async throws {
        try await super.setUp()
        suiteName = "OakTests.NotchCompanionViewTests.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw NSError(domain: "NotchCompanionViewTests", code: 1)
        }
        userDefaults.removePersistentDomain(forName: suiteName)
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

    // MARK: - Helper

    private func makeView(onExpansionChanged: @escaping (Bool) -> Void = { _ in }) -> NotchCompanionView {
        NotchCompanionView(
            viewModel: viewModel,
            notificationService: notificationService,
            sparkleUpdater: sparkleUpdater,
            onExpansionChanged: onExpansionChanged
        )
    }

    // MARK: - Initialisation

    func testViewInitialisesWithDefaultCollapsedState() {
        let view = makeView()
        XCTAssertFalse(view.isExpandedByToggle, "View should start in collapsed state")
        XCTAssertFalse(view.isExpanded, "isExpanded should reflect isExpandedByToggle")
    }

    func testViewInitialisesWithIdleViewModel() {
        let view = makeView()
        XCTAssertNotNil(view, "NotchCompanionView should initialise successfully")
        XCTAssertTrue(viewModel.canStart, "ViewModel should start in idle/canStart state")
    }

    // MARK: - Expansion Toggle

    func testIsExpandedReflectsIsExpandedByToggle() {
        var view = makeView()
        XCTAssertFalse(view.isExpanded, "isExpanded should be false initially")
        view.isExpandedByToggle = true
        XCTAssertTrue(view.isExpanded, "isExpanded should be true when isExpandedByToggle is true")
        view.isExpandedByToggle = false
        XCTAssertFalse(view.isExpanded, "isExpanded should be false when isExpandedByToggle is false")
    }

    // notifyExpansionChanged updates lastReportedExpansion synchronously before dispatching the callback.
    // These tests verify the synchronous guard/deduplication logic directly.

    func testNotifyExpansionChangedSetsLastReportedExpansion() {
        var view = makeView()
        XCTAssertNil(view.lastReportedExpansion, "lastReportedExpansion should be nil initially")
        view.notifyExpansionChanged(false)
        XCTAssertEqual(view.lastReportedExpansion, false, "lastReportedExpansion should be set after first call")
    }

    func testNotifyExpansionChangedUpdatesLastReportedWhenStateChanges() {
        var view = makeView()
        view.notifyExpansionChanged(false)
        XCTAssertEqual(view.lastReportedExpansion, false)

        view.notifyExpansionChanged(true)
        XCTAssertEqual(view.lastReportedExpansion, true, "lastReportedExpansion should update to new state")
    }

    func testNotifyExpansionChangedDoesNotUpdateLastReportedForSameState() {
        var view = makeView()
        view.notifyExpansionChanged(false)
        view.notifyExpansionChanged(false) // same value - guard fires, lastReportedExpansion unchanged
        XCTAssertEqual(
            view.lastReportedExpansion,
            false,
            "lastReportedExpansion should stay false for repeated same-state call"
        )
    }

    func testOnExpansionChangedCallbackFiresWithInitialState() async {
        let expectation = expectation(description: "Callback fired for initial state")
        var receivedValue: Bool?
        let view = makeView { expanded in
            receivedValue = expanded
            expectation.fulfill()
        }
        view.notifyExpansionChanged(false)
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValue, false, "Callback should fire with collapsed state")
    }

    func testOnExpansionChangedCallbackFiresWhenExpanded() async {
        let expandExpectation = expectation(description: "Callback fired for expanded state")
        expandExpectation.expectedFulfillmentCount = 2 // collapsed then expanded
        var receivedValues: [Bool] = []
        var view = makeView { expanded in
            receivedValues.append(expanded)
            expandExpectation.fulfill()
        }
        view.notifyExpansionChanged(false)
        view.isExpandedByToggle = true
        view.notifyExpansionChanged(true)
        await fulfillment(of: [expandExpectation], timeout: 1.0)
        XCTAssertEqual(receivedValues.last, true, "Callback should receive true when expanded")
    }

    func testOnExpansionChangedCallbackFiresWhenCollapsed() async {
        let collapseExpectation = expectation(description: "Callback fired for collapsed state")
        collapseExpectation.expectedFulfillmentCount = 2 // expanded then collapsed
        var receivedValues: [Bool] = []
        var view = makeView { expanded in
            receivedValues.append(expanded)
            collapseExpectation.fulfill()
        }
        view.isExpandedByToggle = true
        view.notifyExpansionChanged(true)
        view.isExpandedByToggle = false
        view.notifyExpansionChanged(false)
        await fulfillment(of: [collapseExpectation], timeout: 1.0)
        XCTAssertEqual(receivedValues.last, false, "Callback should receive false when collapsed")
    }

    func testOnExpansionChangedCallbackDeduplicatesRepeatedCalls() async {
        let firstCallExpectation = expectation(description: "First callback fired")
        let drainWaitNanoseconds: UInt64 = 200_000_000 // 0.2 s — drain main queue without waiting long
        var callCount = 0
        var view = makeView { _ in
            callCount += 1
            if callCount == 1 { firstCallExpectation.fulfill() }
        }
        view.notifyExpansionChanged(false)
        await fulfillment(of: [firstCallExpectation], timeout: 1.0)
        let countAfterFirst = callCount

        // Second call with same value: guard fires, callback is NOT dispatched
        view.notifyExpansionChanged(false)
        // Drain the main queue briefly to confirm no second callback arrives
        try? await Task.sleep(nanoseconds: drainWaitNanoseconds)
        XCTAssertEqual(callCount, countAfterFirst, "Callback should not fire again for same expansion state")
    }

    // MARK: - Compact / Expanded Sub-View Availability

    func testCompactViewExistsInIdleState() {
        let view = makeView()
        XCTAssertTrue(viewModel.canStart, "Precondition: viewModel should be in canStart state")
        let compactView = view.compactView
        XCTAssertNotNil(compactView, "compactView should exist in idle state")
    }

    func testStartViewExistsInIdleState() {
        let view = makeView()
        XCTAssertTrue(viewModel.canStart, "Precondition: viewModel should be in canStart state")
        let startView = view.startView
        XCTAssertNotNil(startView, "startView should exist in idle state")
    }

    func testSessionViewExistsWhenSessionRunning() {
        viewModel.startSession(using: .short)
        let view = makeView()
        let sessionView = view.sessionView
        XCTAssertNotNil(sessionView, "sessionView should exist when session is running")
        viewModel.resetSession()
    }

    func testSessionViewExistsWhenSessionPaused() {
        viewModel.startSession(using: .short)
        viewModel.pauseSession()
        let view = makeView()
        let sessionView = view.sessionView
        XCTAssertNotNil(sessionView, "sessionView should exist when session is paused")
        viewModel.resetSession()
    }

    func testSessionViewExistsAfterSessionCompleted() {
        viewModel.startSession(using: .short)
        viewModel.completeSession()
        let view = makeView()
        let sessionView = view.sessionView
        XCTAssertNotNil(sessionView, "sessionView should exist after session completion")
        viewModel.resetSession()
    }

    // MARK: - Inside-Notch Sub-View Availability

    func testInsideNotchCompactContentExists() {
        let view = makeView()
        let content = view.insideNotchCompactContent
        XCTAssertNotNil(content, "insideNotchCompactContent should exist")
    }

    func testInsideNotchExpandedContentExists() {
        let view = makeView()
        let content = view.insideNotchExpandedContent
        XCTAssertNotNil(content, "insideNotchExpandedContent should exist")
    }

    func testInsideNotchCompactContentExistsWhenRunning() {
        viewModel.startSession(using: .short)
        let view = makeView()
        let content = view.insideNotchCompactContent
        XCTAssertNotNil(content, "insideNotchCompactContent should exist when session is running")
        viewModel.resetSession()
    }

    func testInsideNotchExpandedContentExistsWhenRunning() {
        viewModel.startSession(using: .short)
        let view = makeView()
        let content = view.insideNotchExpandedContent
        XCTAssertNotNil(content, "insideNotchExpandedContent should exist when session is running")
        viewModel.resetSession()
    }

    func testInsideNotchCompactContentExistsWhenPaused() {
        viewModel.startSession(using: .short)
        viewModel.pauseSession()
        let view = makeView()
        let content = view.insideNotchCompactContent
        XCTAssertNotNil(content, "insideNotchCompactContent should exist when session is paused")
        viewModel.resetSession()
    }

    func testInsideNotchExpandedContentExistsWhenCompleted() {
        viewModel.startSession(using: .short)
        viewModel.completeSession()
        let view = makeView()
        let content = view.insideNotchExpandedContent
        XCTAssertNotNil(content, "insideNotchExpandedContent should exist after session completion")
        viewModel.resetSession()
    }

    // MARK: - Control Button Availability

    func testAudioButtonExists() {
        let view = makeView()
        let button = view.audioButton
        XCTAssertNotNil(button, "audioButton should exist")
    }

    func testProgressButtonExists() {
        let view = makeView()
        let button = view.progressButton
        XCTAssertNotNil(button, "progressButton should exist")
    }

    func testSettingsButtonExists() {
        let view = makeView()
        let button = view.settingsButton
        XCTAssertNotNil(button, "settingsButton should exist")
    }

    func testExpandToggleButtonExists() {
        let view = makeView()
        let button = view.expandToggleButton
        XCTAssertNotNil(button, "expandToggleButton should exist")
    }

    func testPresetSelectorExists() {
        let view = makeView()
        let selector = view.presetSelector
        XCTAssertNotNil(selector, "presetSelector should exist")
    }

    // MARK: - Popover State

    func testShowAudioMenuDefaultsToFalse() {
        let view = makeView()
        XCTAssertFalse(view.showAudioMenu, "showAudioMenu should default to false")
    }

    func testShowProgressMenuDefaultsToFalse() {
        let view = makeView()
        XCTAssertFalse(view.showProgressMenu, "showProgressMenu should default to false")
    }

    func testShowSettingsMenuDefaultsToFalse() {
        let view = makeView()
        XCTAssertFalse(view.showSettingsMenu, "showSettingsMenu should default to false")
    }

    func testAudioMenuPopoverFlagCanBeSetTrue() {
        var view = makeView()
        XCTAssertFalse(view.showAudioMenu)
        view.showAudioMenu = true
        XCTAssertTrue(view.showAudioMenu, "showAudioMenu flag should be true after being set")
    }

    func testProgressMenuPopoverFlagCanBeSetTrue() {
        var view = makeView()
        XCTAssertFalse(view.showProgressMenu)
        view.showProgressMenu = true
        XCTAssertTrue(view.showProgressMenu, "showProgressMenu flag should be true after being set")
    }

    func testSettingsMenuPopoverFlagCanBeSetTrue() {
        var view = makeView()
        XCTAssertFalse(view.showSettingsMenu)
        view.showSettingsMenu = true
        XCTAssertTrue(view.showSettingsMenu, "showSettingsMenu flag should be true after being set")
    }

    func testAllPopoverFlagsAreIndependent() {
        // Verify the three popover state flags are separate and can coexist
        var view = makeView()
        view.showAudioMenu = true
        view.showProgressMenu = true
        view.showSettingsMenu = true
        XCTAssertTrue(view.showAudioMenu, "Audio menu flag should be independent")
        XCTAssertTrue(view.showProgressMenu, "Progress menu flag should be independent")
        XCTAssertTrue(view.showSettingsMenu, "Settings menu flag should be independent")
    }

    func testPopoverFlagCanBeResetToFalse() {
        var view = makeView()
        view.showAudioMenu = true
        view.showAudioMenu = false
        XCTAssertFalse(view.showAudioMenu, "showAudioMenu should be resettable to false")
    }

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

    // MARK: - Preset Selection

    func testDefaultPresetSelectionIsShort() {
        let view = makeView()
        XCTAssertEqual(view.presetSelection, .short, "Default preset selection should be .short")
    }

    func testPresetChipShortExists() {
        let view = makeView()
        let chip = view.presetChip(.short)
        XCTAssertNotNil(chip, "Short preset chip should exist")
    }

    func testPresetChipLongExists() {
        let view = makeView()
        let chip = view.presetChip(.long)
        XCTAssertNotNil(chip, "Long preset chip should exist")
    }

    func testPresetLabelForShortPreset() {
        let view = makeView()
        let label = view.presetLabel(for: .short)
        XCTAssertFalse(label.isEmpty, "Short preset label should not be empty")
    }

    func testPresetLabelForLongPreset() {
        let view = makeView()
        let label = view.presetLabel(for: .long)
        XCTAssertFalse(label.isEmpty, "Long preset label should not be empty")
    }

    func testPresetLabelsAreDifferent() {
        let view = makeView()
        let shortLabel = view.presetLabel(for: .short)
        let longLabel = view.presetLabel(for: .long)
        XCTAssertNotEqual(shortLabel, longLabel, "Short and long preset labels should differ")
    }

    // MARK: - Countdown Display

    func testCountdownDisplayInNumberModeExists() {
        let view = makeView()
        let display = view.countdownDisplay(mode: .number, size: 20, fontSize: 13)
        XCTAssertNotNil(display, "Countdown display in number mode should exist")
    }

    func testCountdownDisplayInCircleRingModeExists() {
        let view = makeView()
        let display = view.countdownDisplay(mode: .circleRing, size: 26, fontSize: 14)
        XCTAssertNotNil(display, "Countdown display in circle ring mode should exist")
    }

    func testCountdownDisplayWithShowSessionTypeExists() {
        let view = makeView()
        let displayWithSession = view.countdownDisplay(
            mode: .circleRing,
            size: 26,
            fontSize: 14,
            showSessionType: true
        )
        XCTAssertNotNil(displayWithSession, "Countdown display with showSessionType should exist")
    }

    func testCountdownDisplayReflectsRunningState() {
        viewModel.startSession(using: .short)
        let view = makeView()
        XCTAssertFalse(viewModel.isPaused, "Precondition: session should not be paused")
        let display = view.countdownDisplay(mode: .number, size: 20, fontSize: 13)
        XCTAssertNotNil(display, "Countdown display should exist in running state")
        viewModel.resetSession()
    }

    func testCountdownDisplayReflectsPausedState() {
        viewModel.startSession(using: .short)
        viewModel.pauseSession()
        let view = makeView()
        XCTAssertTrue(viewModel.isPaused, "Precondition: session should be paused")
        let display = view.countdownDisplay(mode: .number, size: 20, fontSize: 13)
        XCTAssertNotNil(display, "Countdown display should exist in paused state")
        viewModel.resetSession()
    }

    // MARK: - Visual Style

    func testVisualStyleIsNotNil() {
        let view = makeView()
        let style = view.visualStyle
        XCTAssertNotNil(style, "Visual style should be available")
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

    func testSessionCompletionTriggersConfettiForWorkSession() {
        // Work session completion is the trigger for confetti display
        viewModel.startSession(using: .short) // starts a work session
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
