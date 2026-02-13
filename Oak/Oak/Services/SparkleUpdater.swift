import AppKit
import Foundation
import os
import Sparkle

private let sparkleAppcastFeedURL = "https://raw.githubusercontent.com/jellydn/oak/main/appcast.xml"

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
            userDriverDelegate: self
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
        Task { [weak self] in
            await self?.performManualUpdateCheck(using: updaterController)
        }
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
        sparkleAppcastFeedURL
    }
}

internal enum AppcastVersionParser {
    static func latestShortVersion(in xml: String) -> String? {
        guard let regex = try? NSRegularExpression(
            pattern: "<sparkle:shortVersionString>\\s*([^<\\s]+)\\s*</sparkle:shortVersionString>",
            options: [.caseInsensitive]
        ) else {
            return nil
        }

        guard let match = regex.firstMatch(in: xml, range: NSRange(xml.startIndex ..< xml.endIndex, in: xml)),
              let versionRange = Range(match.range(at: 1), in: xml)
        else {
            return nil
        }

        let version = xml[versionRange].trimmingCharacters(in: .whitespacesAndNewlines)
        return version.isEmpty ? nil : version
    }
}

@MainActor
extension SparkleUpdater: @preconcurrency SPUStandardUserDriverDelegate {
    var supportsGentleScheduledUpdateReminders: Bool {
        true
    }

    func standardUserDriverWillHandleShowingUpdate(
        _: Bool,
        forUpdate _: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        // Background-only apps should request user attention when a scheduled update is presented.
        guard !state.userInitiated else { return }
        NSApp.requestUserAttention(.informationalRequest)
    }
}

private extension SparkleUpdater {
    func performManualUpdateCheck(using updaterController: SPUStandardUpdaterController) async {
        let currentVersion = currentShortVersion()
        let feedVersion = await fetchLatestFeedVersion()

        if let currentVersion, let feedVersion {
            let isFeedOlderThanInstalled =
                feedVersion.compare(currentVersion, options: .numeric) == .orderedAscending

            guard isFeedOlderThanInstalled else {
                updaterController.checkForUpdates(nil)
                logger.info("Manual update check triggered")
                return
            }

            logger.warning(
                """
                Update feed is behind current app version. \
                Feed: \(feedVersion, privacy: .public), \
                current: \(currentVersion, privacy: .public)
                """
            )
            showFeedBehindAlert(currentVersion: currentVersion, feedVersion: feedVersion)
            return
        }

        updaterController.checkForUpdates(nil)
        logger.info("Manual update check triggered")
    }

    func currentShortVersion() -> String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    func fetchLatestFeedVersion() async -> String? {
        guard let feedURL = URL(string: sparkleAppcastFeedURL)
        else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: feedURL)
            guard let xml = String(data: data, encoding: .utf8) else {
                return nil
            }
            return AppcastVersionParser.latestShortVersion(in: xml)
        } catch {
            logger.warning("Failed to preflight appcast version: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func showFeedBehindAlert(currentVersion: String, feedVersion: String) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "No New Update Available"
        alert.informativeText = "Installed version \(currentVersion) is newer than appcast version \(feedVersion)."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    static var hasValidPublicEDKey: Bool {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String else {
            return false
        }

        let key = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return !key.isEmpty && !key.contains("$(")
    }
}
