import Foundation
import Sparkle
import os

@MainActor
internal final class SparkleUpdater: NSObject, ObservableObject {
    @Published var canCheckForUpdates = false
    @Published var automaticallyChecksForUpdates = true
    @Published var automaticallyDownloadsUpdates = false

    private let updaterController: SPUStandardUpdaterController
    private let logger = Logger(subsystem: "com.productsway.oak.app", category: "SparkleUpdater")

    override init() {
        self.updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        super.init()

        self.canCheckForUpdates = updaterController.updater.canCheckForUpdates
        self.automaticallyChecksForUpdates = updaterController.updater.automaticallyChecksForUpdates
        self.automaticallyDownloadsUpdates = updaterController.updater.automaticallyDownloadsUpdates

        logger.info("Sparkle updater initialized")
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
        logger.info("Manual update check triggered")
    }

    func setAutomaticallyChecksForUpdates(_ enabled: Bool) {
        updaterController.updater.automaticallyChecksForUpdates = enabled
        automaticallyChecksForUpdates = enabled
        logger.info("Automatic update checks: \(enabled ? "enabled" : "disabled")")
    }

    func setAutomaticallyDownloadsUpdates(_ enabled: Bool) {
        updaterController.updater.automaticallyDownloadsUpdates = enabled
        automaticallyDownloadsUpdates = enabled
        logger.info("Automatic downloads: \(enabled ? "enabled" : "disabled")")
    }
}
