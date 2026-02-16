import SwiftUI

internal struct NotificationSettingsView: View {
    @ObservedObject var presetSettings: PresetSettingsStore
    @ObservedObject var notificationService: NotificationService

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(notificationStatusText)
                .font(.caption)
                .foregroundColor(.secondary)

            Toggle(
                "Play completion sound",
                isOn: Binding(
                    get: { presetSettings.playSoundOnSessionCompletion },
                    set: { presetSettings.setPlaySoundOnSessionCompletion($0) }
                )
            )
            .font(.caption)

            Toggle(
                "Play sound on break completion",
                isOn: Binding(
                    get: { presetSettings.playSoundOnBreakCompletion },
                    set: { presetSettings.setPlaySoundOnBreakCompletion($0) }
                )
            )
            .font(.caption)
            .disabled(!presetSettings.playSoundOnSessionCompletion)

            HStack(spacing: 8) {
                if notificationService.authorizationStatus == .notDetermined {
                    Button("Allow Notifications") {
                        Task {
                            await notificationService.requestAuthorization()
                        }
                    }
                } else if !notificationService.isAuthorized {
                    Button("Open System Settings") {
                        notificationService.openNotificationSettings()
                    }
                }

                Button("Refresh Status") {
                    Task {
                        await notificationService.refreshAuthorizationStatus()
                    }
                }
            }
            .buttonStyle(.link)
        }
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
