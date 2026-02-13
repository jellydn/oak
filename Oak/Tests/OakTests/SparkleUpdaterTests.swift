import XCTest
@testable import Oak

@MainActor
internal final class SparkleUpdaterTests: XCTestCase {
    var updater: SparkleUpdater!

    override func setUp() async throws {
        updater = SparkleUpdater()
    }

    override func tearDown() async throws {
        updater = nil
    }

    func testUpdaterInitialization() async throws {
        XCTAssertNotNil(updater, "SparkleUpdater should initialize successfully")
    }

    func testCanCheckForUpdatesProperty() async throws {
        // canCheckForUpdates should be accessible
        _ = updater.canCheckForUpdates
    }

    func testAutomaticallyChecksForUpdatesProperty() async throws {
        // automaticallyChecksForUpdates should be accessible
        _ = updater.automaticallyChecksForUpdates
    }

    func testAutomaticallyDownloadsUpdatesProperty() async throws {
        // automaticallyDownloadsUpdates should be accessible
        _ = updater.automaticallyDownloadsUpdates
    }

    func testSetAutomaticallyChecksForUpdates() async throws {
        let initialValue = updater.automaticallyChecksForUpdates

        updater.setAutomaticallyChecksForUpdates(!initialValue)

        XCTAssertEqual(
            updater.automaticallyChecksForUpdates,
            !initialValue,
            "automaticallyChecksForUpdates should be updated"
        )

        updater.setAutomaticallyChecksForUpdates(initialValue)

        XCTAssertEqual(
            updater.automaticallyChecksForUpdates,
            initialValue,
            "automaticallyChecksForUpdates should be restored"
        )
    }

    func testSetAutomaticallyDownloadsUpdates() async throws {
        let initialValue = updater.automaticallyDownloadsUpdates

        updater.setAutomaticallyDownloadsUpdates(!initialValue)

        XCTAssertEqual(
            updater.automaticallyDownloadsUpdates,
            !initialValue,
            "automaticallyDownloadsUpdates should be updated"
        )

        updater.setAutomaticallyDownloadsUpdates(initialValue)

        XCTAssertEqual(
            updater.automaticallyDownloadsUpdates,
            initialValue,
            "automaticallyDownloadsUpdates should be restored"
        )
    }

    func testCheckForUpdatesDoesNotCrash() async throws {
        // This test verifies that checkForUpdates can be called without crashing
        // The actual update check is managed by Sparkle and would require network access
        updater.checkForUpdates()
        // If we get here without crashing, the test passes
    }
}
