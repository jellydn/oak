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

    // NOTE: Tests for @State properties (isExpandedByToggle, lastReportedExpansion) and
    // notifyExpansionChanged are omitted — @State storage is managed by SwiftUI's rendering
    // pipeline and cannot be mutated or observed outside a hosted View body.
}
