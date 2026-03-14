import SwiftUI
import XCTest
@testable import Oak

// MARK: - NotchCompanionViewTests

@MainActor
internal final class NotchCompanionViewTests: XCTestCase {
    var viewModel: FocusSessionViewModel!
    var notificationService: NotificationService!
    var sparkleUpdater: SparkleUpdater!
    var presetSettings: PresetSettingsStore!
    var suiteName: String!

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

    func makeView(onExpansionChanged: @escaping (Bool) -> Void = { _ in }) -> NotchCompanionView {
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
        XCTAssertTrue(viewModel.canStart, "ViewModel should start in idle/canStart state")
    }

    // MARK: - Expansion Toggle

    func testIsExpandedReflectsIsExpandedByToggle() {
        let view = makeView()
        XCTAssertFalse(view.isExpanded, "isExpanded should be false initially")
        view.isExpandedByToggle = true
        XCTAssertTrue(view.isExpanded, "isExpanded should be true when isExpandedByToggle is true")
        view.isExpandedByToggle = false
        XCTAssertFalse(view.isExpanded, "isExpanded should be false when isExpandedByToggle is false")
    }

    // notifyExpansionChanged updates lastReportedExpansion synchronously before dispatching the callback.
    // These tests verify the synchronous guard/deduplication logic directly.

    func testNotifyExpansionChangedSetsLastReportedExpansion() {
        let view = makeView()
        XCTAssertNil(view.lastReportedExpansion, "lastReportedExpansion should be nil initially")
        view.notifyExpansionChanged(false)
        XCTAssertEqual(view.lastReportedExpansion, false, "lastReportedExpansion should be set after first call")
    }

    func testNotifyExpansionChangedUpdatesLastReportedWhenStateChanges() {
        let view = makeView()
        view.notifyExpansionChanged(false)
        XCTAssertEqual(view.lastReportedExpansion, false)
        view.notifyExpansionChanged(true)
        XCTAssertEqual(view.lastReportedExpansion, true, "lastReportedExpansion should update to new state")
    }

    func testNotifyExpansionChangedDoesNotUpdateLastReportedForSameState() {
        let view = makeView()
        view.notifyExpansionChanged(false)
        view.notifyExpansionChanged(false)
        XCTAssertEqual(
            view.lastReportedExpansion,
            false,
            "lastReportedExpansion should stay false for repeated same-state call"
        )
    }

    // MARK: - Expansion Callbacks

    func testOnExpansionChangedCallbackFiresWithInitialState() async {
        let callbackExpectation = expectation(description: "Callback fired for initial state")
        var receivedValue: Bool?
        let view = makeView { expanded in
            receivedValue = expanded
            callbackExpectation.fulfill()
        }
        view.notifyExpansionChanged(false)
        await fulfillment(of: [callbackExpectation], timeout: 1.0)
        XCTAssertEqual(receivedValue, false, "Callback should fire with collapsed state")
    }

    func testOnExpansionChangedCallbackFiresWhenExpanded() async {
        let expandExpectation = expectation(description: "Callback fired for expanded state")
        expandExpectation.expectedFulfillmentCount = 2
        var receivedValues: [Bool] = []
        let view = makeView { expanded in
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
        collapseExpectation.expectedFulfillmentCount = 2
        var receivedValues: [Bool] = []
        let view = makeView { expanded in
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
        // Inverted expectation — fulfilled if a second callback fires (which should NOT happen)
        let noSecondCallExpectation = expectation(description: "No second callback for same state")
        noSecondCallExpectation.isInverted = true
        var callCount = 0
        let view = makeView { _ in
            callCount += 1
            if callCount == 1 {
                firstCallExpectation.fulfill()
            } else {
                noSecondCallExpectation.fulfill()
            }
        }
        view.notifyExpansionChanged(false)
        await fulfillment(of: [firstCallExpectation], timeout: 1.0)

        // Second call with same value: guard fires, callback is NOT dispatched
        view.notifyExpansionChanged(false)
        await fulfillment(of: [noSecondCallExpectation], timeout: 0.5)
        XCTAssertEqual(callCount, 1, "Callback should only fire once for repeated same state")
    }
}
