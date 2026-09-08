import SwiftUI

internal struct NotificationSettingsView: View {
    @ObservedObject internal var presetSettings: PresetSettingsStore
    @ObservedObject internal var notificationService: NotificationService

    private var palette: ThemePalette {
        presetSettings.theme.palette
    }

    internal var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: notificationStatusImage)
                    .foregroundColor(notificationService.isAuthorized ? palette.success : palette.warning)
                    .frame(width: 18)

                Text(notificationStatusText)
                    .font(.callout)
                    .foregroundColor(palette.secondaryForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }

            notificationActions

            Divider()

            notificationToggle(
                "Session completion sound",
                description: "Play a sound when a focus session ends.",
                isOn: Binding(
                    get: { presetSettings.playSoundOnSessionCompletion },
                    set: { presetSettings.setPlaySoundOnSessionCompletion($0) }
                )
            )

            notificationToggle(
                "Break completion sound",
                description: "Play a sound when a break ends.",
                isOn: Binding(
                    get: { presetSettings.playSoundOnBreakCompletion },
                    set: { presetSettings.setPlaySoundOnBreakCompletion($0) }
                )
            )
            .disabled(!presetSettings.playSoundOnSessionCompletion)
        }
    }

    private var notificationActions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                actionButtons
            }

            VStack(alignment: .leading, spacing: 8) {
                actionButtons
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if notificationService.authorizationStatus == .notDetermined {
            Button("Allow Notifications") {
                Task {
                    await notificationService.requestAuthorization()
                }
            }
            .buttonStyle(.borderedProminent)
        } else if !notificationService.isAuthorized {
            Button("Open System Settings") {
                notificationService.openNotificationSettings()
            }
            .buttonStyle(.borderedProminent)
        }

        Button("Refresh Status") {
            Task {
                await notificationService.refreshAuthorizationStatus()
            }
        }
        .buttonStyle(.bordered)
    }

    private func notificationToggle(_ title: String, description: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(description)
                    .font(.caption)
                    .foregroundColor(palette.secondaryForeground)
            }

            Spacer(minLength: 12)

            Toggle(title, isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }

    private var notificationStatusImage: String {
        notificationService.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
    }

    private var notificationStatusText: String {
        switch notificationService.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Notifications are enabled."
        case .notDetermined:
            return "Notifications have not been requested yet."
        case .denied:
            return "Notifications are disabled. Enable them in System Settings."
        @unknown default:
            return "Notification status is unknown."
        }
    }
}
