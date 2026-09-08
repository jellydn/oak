import SwiftUI

internal struct UpdateSettingsView: View {
    @ObservedObject internal var sparkleUpdater: SparkleUpdater
    internal let theme: AppTheme

    private var palette: ThemePalette { theme.palette }

    internal var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !sparkleUpdater.isConfigured {
                Text("Update signing is not configured (missing SUPublicEDKey).")
                    .font(.caption)
                    .foregroundColor(palette.secondaryForeground)
            }

            updateToggle(
                "Automatically check for updates",
                isOn: Binding(
                    get: { sparkleUpdater.automaticallyChecksForUpdates },
                    set: { sparkleUpdater.setAutomaticallyChecksForUpdates($0) }
                )
            )
            .disabled(!sparkleUpdater.isConfigured)

            updateToggle(
                "Automatically download updates",
                isOn: Binding(
                    get: { sparkleUpdater.automaticallyDownloadsUpdates },
                    set: { sparkleUpdater.setAutomaticallyDownloadsUpdates($0) }
                )
            )
            .disabled(!sparkleUpdater.isConfigured || !sparkleUpdater.automaticallyChecksForUpdates)

            Button("Check for Updates Now") {
                sparkleUpdater.checkForUpdates()
            }
            .buttonStyle(.bordered)
            .disabled(!sparkleUpdater.isConfigured || !sparkleUpdater.canCheckForUpdates)
        }
    }

    private func updateToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 16) {
            Text(title)

            Spacer(minLength: 12)

            Toggle(title, isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }
}
