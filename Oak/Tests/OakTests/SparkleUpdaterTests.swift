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

    func testUpdaterInitialization() {
        XCTAssertNotNil(updater, "SparkleUpdater should initialize successfully")
    }

    func testCanCheckForUpdatesProperty() {
        // canCheckForUpdates should be accessible
        _ = updater.canCheckForUpdates
    }

    func testAutomaticallyChecksForUpdatesProperty() {
        // automaticallyChecksForUpdates should be accessible
        _ = updater.automaticallyChecksForUpdates
    }

    func testAutomaticallyDownloadsUpdatesProperty() {
        // automaticallyDownloadsUpdates should be accessible
        _ = updater.automaticallyDownloadsUpdates
    }

    func testSetAutomaticallyChecksForUpdates() {
        guard updater.isConfigured else { return }

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

    func testSetAutomaticallyDownloadsUpdates() {
        guard updater.isConfigured else { return }

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

    func testCheckForUpdatesDoesNotCrash() {
        XCTAssertNoThrow(
            updater.checkForUpdates(),
            "checkForUpdates should be callable without throwing"
        )
    }
}
