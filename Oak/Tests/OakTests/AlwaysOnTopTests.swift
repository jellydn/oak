import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class AlwaysOnTopTests: XCTestCase {
    var presetSettings: PresetSettingsStore!
    var presetSuiteName: String!
    var userDefaults: UserDefaults!

    override func setUp() async throws {
        let suiteName = "OakTests.AlwaysOnTop.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw NSError(domain: "AlwaysOnTopTests", code: 1)
        }
        defaults.removePersistentDomain(forName: suiteName)
        presetSuiteName = suiteName
        userDefaults = defaults
        presetSettings = PresetSettingsStore(userDefaults: defaults)
    }

    override func tearDown() async throws {
        if let presetSuiteName {
            UserDefaults(suiteName: presetSuiteName)?.removePersistentDomain(forName: presetSuiteName)
        }
        presetSettings = nil
        userDefaults = nil
    }

    // MARK: - Default Value Tests

    func testAlwaysOnTopDefaultsToTrue() {
        XCTAssertTrue(presetSettings.alwaysOnTop, "alwaysOnTop should default to true")
    }

    // MARK: - Setter Tests

    func testSetAlwaysOnTopToTrue() {
        presetSettings.setAlwaysOnTop(true)
        XCTAssertTrue(presetSettings.alwaysOnTop, "alwaysOnTop should be true after setting")
    }

    func testSetAlwaysOnTopToFalse() {
        presetSettings.setAlwaysOnTop(true)
        presetSettings.setAlwaysOnTop(false)
        XCTAssertFalse(presetSettings.alwaysOnTop, "alwaysOnTop should be false after setting")
    }

    func testSetAlwaysOnTopToSameValueDoesNotTriggerChange() {
        presetSettings.setAlwaysOnTop(false)
        let initial = presetSettings.alwaysOnTop

        presetSettings.setAlwaysOnTop(false)
        let final = presetSettings.alwaysOnTop

        XCTAssertEqual(initial, final, "Setting to same value should not trigger change")
    }

    // MARK: - Persistence Tests

    func testAlwaysOnTopPersistsToUserDefaults() {
        presetSettings.setAlwaysOnTop(true)

        let persistedValue = userDefaults.bool(forKey: "window.alwaysOnTop")
        XCTAssertTrue(persistedValue, "alwaysOnTop value should persist to UserDefaults")
    }

    func testAlwaysOnTopLoadedFromUserDefaults() {
        userDefaults.set(true, forKey: "window.alwaysOnTop")

        let newSettings = PresetSettingsStore(userDefaults: userDefaults)
        XCTAssertTrue(newSettings.alwaysOnTop, "alwaysOnTop should load from UserDefaults")
    }

    func testAlwaysOnTopFalseLoadedFromUserDefaults() {
        userDefaults.set(false, forKey: "window.alwaysOnTop")

        let newSettings = PresetSettingsStore(userDefaults: userDefaults)
        XCTAssertFalse(newSettings.alwaysOnTop, "alwaysOnTop false should load from UserDefaults")
    }

    // MARK: - Reset to Default Tests

    func testResetToDefaultSetsAlwaysOnTopToTrue() {
        presetSettings.setAlwaysOnTop(false)
        XCTAssertFalse(presetSettings.alwaysOnTop, "Precondition: alwaysOnTop should be false")

        presetSettings.resetToDefault()

        XCTAssertTrue(presetSettings.alwaysOnTop, "resetToDefault should set alwaysOnTop to true")
    }

    func testResetToDefaultPersistsAlwaysOnTopToUserDefaults() {
        presetSettings.setAlwaysOnTop(false)
        presetSettings.resetToDefault()

        let persistedValue = userDefaults.bool(forKey: "window.alwaysOnTop")
        XCTAssertTrue(persistedValue, "resetToDefault should persist true to UserDefaults")
    }

    // MARK: - Published Property Tests

    func testAlwaysOnTopIsPublished() async {
        let expectation = expectation(description: "Published value changed")
        var receivedValue: Bool?

        let cancellable = presetSettings.$alwaysOnTop
            .dropFirst() // Skip initial value
            .sink { value in
                receivedValue = value
                expectation.fulfill()
            }

        presetSettings.setAlwaysOnTop(false)

        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertEqual(receivedValue, false, "Published property should emit new value")
        cancellable.cancel()
    }
}
