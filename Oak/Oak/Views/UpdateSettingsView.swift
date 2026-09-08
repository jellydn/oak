import SwiftUI

internal struct UpdateSettingsView: View {
    @ObservedObject var sparkleUpdater: SparkleUpdater
    var theme: AppTheme = .oak

    private var palette: ThemePalette { theme.palette }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !sparkleUpdater.isConfigured {
                Text("Update signing is not configured (missing SUPublicEDKey).")
                    .font(.caption)
                    .foregroundColor(palette.secondaryForeground)
            }

            Toggle(
                "Automatically check for updates",
                isOn: Binding(
                    get: { sparkleUpdater.automaticallyChecksForUpdates },
                    set: { sparkleUpdater.setAutomaticallyChecksForUpdates($0) }
                )
            )
            .font(.caption)
            .disabled(!sparkleUpdater.isConfigured)

            Toggle(
                "Automatically download updates",
                isOn: Binding(
                    get: { sparkleUpdater.automaticallyDownloadsUpdates },
                    set: { sparkleUpdater.setAutomaticallyDownloadsUpdates($0) }
                )
            )
            .font(.caption)
            .disabled(!sparkleUpdater.isConfigured || !sparkleUpdater.automaticallyChecksForUpdates)

            Button("Check for Updates Now") {
                sparkleUpdater.checkForUpdates()
            }
            .buttonStyle(.link)
            .disabled(!sparkleUpdater.isConfigured || !sparkleUpdater.canCheckForUpdates)
        }
    }
}
