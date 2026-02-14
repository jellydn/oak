import XCTest
@testable import Oak

@MainActor
final class PresetSettingsStoreLaunchAtLoginTests: XCTestCase {
    var sut: PresetSettingsStore!
    var userDefaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        // Use a unique suite name for test isolation
        let suiteName = "PresetSettingsStoreLaunchAtLoginTests-\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)!
        sut = PresetSettingsStore(userDefaults: userDefaults)
    }

    override func tearDown() async throws {
        if let suiteName = userDefaults.dictionaryRepresentation().keys.first {
            userDefaults.removePersistentDomain(forName: suiteName)
        }
        userDefaults = nil
        sut = nil
        try await super.tearDown()
    }

    func testLaunchAtLoginDefaultValue() {
        // Default should be false
        XCTAssertFalse(sut.launchAtLogin)
    }

    func testSetLaunchAtLoginTrue() {
        // When
        sut.setLaunchAtLogin(true)

        // Then
        XCTAssertTrue(sut.launchAtLogin)
        XCTAssertTrue(userDefaults.bool(forKey: "general.launchAtLogin"))
    }

    func testSetLaunchAtLoginFalse() {
        // Given
        sut.setLaunchAtLogin(true)

        // When
        sut.setLaunchAtLogin(false)

        // Then
        XCTAssertFalse(sut.launchAtLogin)
        XCTAssertFalse(userDefaults.bool(forKey: "general.launchAtLogin"))
    }

    func testSetLaunchAtLoginWithSameValue() {
        // Given
        sut.setLaunchAtLogin(true)
        let initialValue = sut.launchAtLogin

        // When - set to the same value
        sut.setLaunchAtLogin(true)

        // Then - should remain the same
        XCTAssertEqual(sut.launchAtLogin, initialValue)
        XCTAssertTrue(sut.launchAtLogin)
    }

    func testLaunchAtLoginPersistence() {
        // Given
        sut.setLaunchAtLogin(true)

        // When - create a new instance with the same UserDefaults
        let newStore = PresetSettingsStore(userDefaults: userDefaults)

        // Then - value should be persisted
        XCTAssertTrue(newStore.launchAtLogin)
    }

    func testResetToDefaultClearsLaunchAtLogin() {
        // Given
        sut.setLaunchAtLogin(true)
        XCTAssertTrue(sut.launchAtLogin)

        // When
        sut.resetToDefault()

        // Then
        XCTAssertFalse(sut.launchAtLogin)
        XCTAssertFalse(userDefaults.bool(forKey: "general.launchAtLogin"))
    }
}
