import XCTest
@testable import Oak

@MainActor
final class LaunchAtLoginServiceTests: XCTestCase {
    var sut: LaunchAtLoginService!

    override func setUp() async throws {
        try await super.setUp()
        // Note: We're testing the service interface, not the actual SMAppService
        // since we can't test that in a unit test environment
        sut = LaunchAtLoginService.shared
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    func testInitialState() {
        // The service should initialize without crashing
        XCTAssertNotNil(sut)
        // isEnabled will reflect the actual system state
        // We can't assert a specific value since it depends on system configuration
    }

    func testSetEnabledDoesNotCrash() {
        // Test that calling setEnabled doesn't crash
        // The actual registration might fail in test environment, but that's expected
        sut.setEnabled(true)
        sut.setEnabled(false)
        // If we get here without crashing, the test passes
    }

    func testRefreshStatusDoesNotCrash() {
        // Test that refreshing status doesn't crash
        sut.refreshStatus()
        // If we get here without crashing, the test passes
    }

    func testSetEnabledWithSameValueDoesNothing() {
        let initialState = sut.isEnabled
        // Set to the same value
        sut.setEnabled(initialState)
        // Should remain the same
        XCTAssertEqual(sut.isEnabled, initialState)
    }
}
