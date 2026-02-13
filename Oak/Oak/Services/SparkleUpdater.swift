import Foundation
import os
import Sparkle

@MainActor
internal final class SparkleUpdater: NSObject, ObservableObject, SPUUpdaterDelegate {
    internal static let shared = SparkleUpdater()

    @Published var canCheckForUpdates = false
    @Published var automaticallyChecksForUpdates = true
    @Published var automaticallyDownloadsUpdates = false
    @Published private(set) var isConfigured = false

    private var updaterController: SPUStandardUpdaterController?
    private let logger = Logger(subsystem: "com.productsway.oak.app", category: "SparkleUpdater")

    override init() {
        super.init()

        guard Self.hasValidPublicEDKey else {
            logger.warning("Sparkle updates disabled because SUPublicEDKey is missing or invalid")
            return
        }

        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self,
            userDriverDelegate: nil
        )
        updaterController = controller
        isConfigured = true
        canCheckForUpdates = controller.updater.canCheckForUpdates
        automaticallyChecksForUpdates = controller.updater.automaticallyChecksForUpdates
        automaticallyDownloadsUpdates = controller.updater.automaticallyDownloadsUpdates

        logger.info("Sparkle updater initialized")
    }

    func checkForUpdates() {
        guard let updaterController else { return }
        updaterController.checkForUpdates(nil)
        logger.info("Manual update check triggered")
    }

    func setAutomaticallyChecksForUpdates(_ enabled: Bool) {
        guard let updaterController else { return }
        updaterController.updater.automaticallyChecksForUpdates = enabled
        automaticallyChecksForUpdates = enabled
        logger.info("Automatic update checks: \(enabled ? "enabled" : "disabled")")
    }

    func setAutomaticallyDownloadsUpdates(_ enabled: Bool) {
        guard let updaterController else { return }
        updaterController.updater.automaticallyDownloadsUpdates = enabled
        automaticallyDownloadsUpdates = enabled
        logger.info("Automatic downloads: \(enabled ? "enabled" : "disabled")")
    }

    nonisolated func feedURLString(for _: SPUUpdater) -> String? {
        "https://raw.githubusercontent.com/jellydn/oak/main/appcast.xml"
    }
}

private extension SparkleUpdater {
    static var hasValidPublicEDKey: Bool {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String else {
            return false
        }

        let key = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return !key.isEmpty && !key.contains("$(")
    }
}
