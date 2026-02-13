import Foundation
import AppKit
import os

protocol UpdateChecking {
    func checkForUpdatesOnLaunch()
}

final class UpdateChecker: UpdateChecking {
    private let repositoryOwner: String
    private let repositoryName: String
    private let lastPromptedVersionKey = "oak.lastPromptedUpdateVersion"
    private let lastPromptedAtKey = "oak.lastPromptedUpdateAt"
    private let promptCooldown: TimeInterval = 24 * 60 * 60
    private let logger = Logger(subsystem: "com.oak.app", category: "UpdateChecker")
    private let userDefaults: UserDefaults
    private let session: URLSession

    init(
        repositoryOwner: String = "jellydn",
        repositoryName: String = "oak",
        userDefaults: UserDefaults = .standard,
        session: URLSession = .shared
    ) {
        self.repositoryOwner = repositoryOwner
        self.repositoryName = repositoryName
        self.userDefaults = userDefaults
        self.session = session
    }

    func checkForUpdatesOnLaunch() {
        Task {
            await checkForUpdates()
        }
    }

    private func checkForUpdates() async {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return
        }

        guard let releaseURL = latestReleaseURL() else {
            logger.error("Update check skipped: invalid latest release URL")
            return
        }

        var request = URLRequest(url: releaseURL)
        request.timeoutInterval = 10
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Oak/\(currentVersion)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return
            }
            
            // Handle rate limiting
            if httpResponse.statusCode == 403 || httpResponse.statusCode == 429 {
                logger.info("GitHub API rate limited, skipping update check")
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                return
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let latestVersion = normalizedVersion(from: release.tagName)

            guard isRemoteVersionNewer(latestVersion, than: currentVersion) else {
                return
            }

            guard shouldPrompt(for: latestVersion) else {
                return
            }

            await MainActor.run {
                promptForUpdate(version: latestVersion, releaseURL: release.htmlURL)
            }
        } catch {
            logger.error("Update check failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func shouldPrompt(for latestVersion: String) -> Bool {
        let lastVersion = userDefaults.string(forKey: lastPromptedVersionKey)
        let lastPromptTime = userDefaults.object(forKey: lastPromptedAtKey) as? Date

        guard lastVersion == latestVersion, let lastPromptTime else {
            return true
        }

        return Date().timeIntervalSince(lastPromptTime) >= promptCooldown
    }

    private func latestReleaseURL() -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.github.com"
        components.path = "/repos/\(repositoryOwner)/\(repositoryName)/releases/latest"
        return components.url
    }

    @MainActor
    private func promptForUpdate(version: String, releaseURL: URL) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Update Available"
        alert.informativeText = "Oak \(version) is available. Do you want to open the release page now?"
        alert.addButton(withTitle: "Open Release")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        userDefaults.set(version, forKey: lastPromptedVersionKey)
        userDefaults.set(Date(), forKey: lastPromptedAtKey)

        if response == .alertFirstButtonReturn {
            // Validate URL host to prevent MITM attacks
            guard releaseURL.host?.hasSuffix("github.com") == true else {
                logger.warning("Rejected non-GitHub release URL: \(releaseURL, privacy: .public)")
                return
            }
            NSWorkspace.shared.open(releaseURL)
        }
    }

    private func normalizedVersion(from tag: String) -> String {
        if tag.hasPrefix("v") {
            return String(tag.dropFirst())
        }

        return tag
    }

    private func isRemoteVersionNewer(_ remote: String, than local: String) -> Bool {
        remote.compare(local, options: .numeric) == .orderedDescending
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: URL

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}
