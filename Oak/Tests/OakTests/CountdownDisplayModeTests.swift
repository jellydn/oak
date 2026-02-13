import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class CountdownDisplayModeTests: XCTestCase {
    var presetSettings: PresetSettingsStore!
    var viewModel: FocusSessionViewModel!
    var presetSuiteName: String!

    override func setUp() async throws {
        let suiteName = "OakTests.CountdownDisplayMode.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw NSError(domain: "CountdownDisplayModeTests", code: 1)
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

    func testDefaultDisplayModeIsNumber() {
        XCTAssertEqual(presetSettings.countdownDisplayMode, .number)
    }

    func testCanSwitchToCircleRingMode() {
        presetSettings.setCountdownDisplayMode(.circleRing)
        XCTAssertEqual(presetSettings.countdownDisplayMode, .circleRing)
    }

    func testDisplayModeIsPersisted() {
        let suiteName = "OakTests.CountdownDisplayMode.Persistence.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create UserDefaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: suiteName)

        let settings1 = PresetSettingsStore(userDefaults: userDefaults)
        settings1.setCountdownDisplayMode(.circleRing)

        let settings2 = PresetSettingsStore(userDefaults: userDefaults)
        XCTAssertEqual(settings2.countdownDisplayMode, .circleRing)

        userDefaults.removePersistentDomain(forName: suiteName)
    }

    func testProgressPercentageAtStart() {
        XCTAssertEqual(viewModel.progressPercentage, 0.0)
    }

    func testProgressPercentageAfterStart() {
        viewModel.startSession(using: .short)
        XCTAssertGreaterThanOrEqual(viewModel.progressPercentage, 0.0)
        XCTAssertLessThanOrEqual(viewModel.progressPercentage, 1.0)
    }

    func testProgressPercentageAtCompletion() async throws {
        viewModel.completeSessionForTesting()
        XCTAssertEqual(viewModel.progressPercentage, 1.0)
    }

    func testResetToDefaultResetsDisplayMode() {
        presetSettings.setCountdownDisplayMode(.circleRing)
        presetSettings.resetToDefault()
        XCTAssertEqual(presetSettings.countdownDisplayMode, .number)
    }
}
