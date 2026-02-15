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
    private var canCheckObservation: NSKeyValueObservation?
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

        canCheckObservation = controller.updater.observe(
            \.canCheckForUpdates,
            options: [.new]
        ) { [weak self] _, change in
            Task { @MainActor [weak self] in
                self?.canCheckForUpdates = change.newValue ?? false
            }
        }

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
    private struct SemanticVersion: Comparable {
        let major: Int
        let minor: Int
        let patch: Int

        init?(_ value: String) {
            let parts = value.split(separator: ".")
            guard parts.count == 3,
                  let major = Int(parts[0]),
                  let minor = Int(parts[1]),
                  let patch = Int(parts[2])
            else {
                return nil
            }

            self.major = major
            self.minor = minor
            self.patch = patch
        }

        var stringValue: String {
            "\(major).\(minor).\(patch)"
        }

        static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
            if lhs.major != rhs.major {
                return lhs.major < rhs.major
            }
            if lhs.minor != rhs.minor {
                return lhs.minor < rhs.minor
            }
            return lhs.patch < rhs.patch
        }
    }

    static func latestShortVersion(in xml: String) -> String? {
        guard let regex = try? NSRegularExpression(
            pattern: "<sparkle:shortVersionString>\\s*([^<\\s]+)\\s*</sparkle:shortVersionString>",
            options: [.caseInsensitive]
        ) else {
            return nil
        }

        let matches = regex.matches(in: xml, range: NSRange(xml.startIndex ..< xml.endIndex, in: xml))
        let semanticVersions = matches.compactMap { match -> SemanticVersion? in
            guard let versionRange = Range(match.range(at: 1), in: xml) else {
                return nil
            }
            let version = xml[versionRange].trimmingCharacters(in: .whitespacesAndNewlines)
            return SemanticVersion(version)
        }

        return semanticVersions.max()?.stringValue
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
            logger.info(
                """
                Remote appcast latest semver: \(feedVersion, privacy: .public), \
                installed: \(currentVersion, privacy: .public)
                """
            )

            if feedVersion.compare(currentVersion, options: .numeric) == .orderedAscending {
                logger.info(
                    """
                    Installed build is newer than remote appcast. \
                    Proceeding with normal Sparkle check.
                    """
                )
            }
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
            let requestURL: URL
            if var components = URLComponents(url: feedURL, resolvingAgainstBaseURL: false) {
                let timestamp = String(Int(Date().timeIntervalSince1970))
                components.queryItems = (components.queryItems ?? []) + [URLQueryItem(name: "ts", value: timestamp)]
                requestURL = components.url ?? feedURL
            } else {
                requestURL = feedURL
            }

            var request = URLRequest(url: requestURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
            request.setValue("no-cache", forHTTPHeaderField: "Pragma")
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let xml = String(data: data, encoding: .utf8) else {
                return nil
            }
            return AppcastVersionParser.latestShortVersion(in: xml)
        } catch {
            logger.warning("Failed to preflight appcast version: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    static var hasValidPublicEDKey: Bool {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String else {
            return false
        }

        let key = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return !key.isEmpty && !key.contains("$(")
    }
}
