import AppKit
import SwiftUI

internal struct SettingsMenuView: View {
    @ObservedObject var presetSettings: PresetSettingsStore
    @ObservedObject var notificationService: NotificationService
    @State private var selectedDisplayTarget: DisplayTarget
    @State private var selectedCountdownDisplayMode: CountdownDisplayMode

    init(
        presetSettings: PresetSettingsStore,
        notificationService: NotificationService
    ) {
        self.presetSettings = presetSettings
        self.notificationService = notificationService
        _selectedDisplayTarget = State(initialValue: presetSettings.displayTarget)
        _selectedCountdownDisplayMode = State(initialValue: presetSettings.countdownDisplayMode)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerRow

            VStack(spacing: 10) {
                displayTargetPicker
                countdownDisplayModePicker
                longBreakCycleEditor
                presetEditor(title: "Preset A", preset: .short)
                presetEditor(title: "Preset B", preset: .long)
                notificationSettings
            }

            Text(validRangeDescription)
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack {
                Button("Reset defaults") {
                    presetSettings.resetToDefault()
                }
                .buttonStyle(.link)

                Spacer()

                Text(currentVersion)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .task {
            await notificationService.refreshAuthorizationStatus()
        }
    }

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Settings")
                    .font(.headline)
                Text("Tune focus presets and notifications.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Quit Oak") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.link)
            .help("Quit Oak")
        }
    }

    private func presetEditor(title: String, preset: Preset) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(title) (\(presetSettings.displayName(for: preset)))")
                .font(.system(size: 11, weight: .semibold))

            HStack(spacing: 8) {
                Text("Focus")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .leading)

                Stepper(
                    value: workMinutesBinding(for: preset),
                    in: PresetSettingsStore.minWorkMinutes ... PresetSettingsStore.maxWorkMinutes
                ) {
                    Text("\(presetSettings.workMinutes(for: preset)) min")
                        .font(.caption)
                }
            }

            HStack(spacing: 8) {
                Text("Break")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .leading)

                Stepper(
                    value: breakMinutesBinding(for: preset),
                    in: PresetSettingsStore.minBreakMinutes ... PresetSettingsStore.maxBreakMinutes
                ) {
                    Text("\(presetSettings.breakMinutes(for: preset)) min")
                        .font(.caption)
                }
            }

            HStack(spacing: 8) {
                Text("Long")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .leading)

                Stepper(
                    value: longBreakMinutesBinding(for: preset),
                    in: PresetSettingsStore.minBreakMinutes ... PresetSettingsStore.maxBreakMinutes
                ) {
                    Text("\(presetSettings.longBreakMinutes(for: preset)) min")
                        .font(.caption)
                }
            }
        }
        .padding(8)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var longBreakCycleEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Long Break Cycle")
                .font(.system(size: 11, weight: .semibold))

            Stepper(
                value: roundsBeforeLongBreakBinding,
                in: PresetSettingsStore.minRoundsBeforeLongBreak ... PresetSettingsStore.maxRoundsBeforeLongBreak
            ) {
                Text("Every \(presetSettings.roundsBeforeLongBreak) focus sessions")
                    .font(.caption)
            }
        }
        .padding(8)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var displayTargetPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Display")
                .font(.system(size: 11, weight: .semibold))

            Picker("Display target", selection: displayTargetBinding) {
                ForEach(DisplayTarget.allCases, id: \.rawValue) { target in
                    Text(
                        NSScreen.displayName(
                            for: target,
                            preferredDisplayID: presetSettings.preferredDisplayID(for: target)
                        )
                    )
                    .tag(target)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: selectedDisplayTarget) { newValue in
                guard presetSettings.displayTarget != newValue else { return }
                DispatchQueue.main.async {
                    presetSettings.setDisplayTarget(newValue)
                }
            }
            .onChange(of: presetSettings.displayTarget) { newValue in
                guard selectedDisplayTarget != newValue else { return }
                selectedDisplayTarget = newValue
            }
        }
        .padding(8)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var countdownDisplayModePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Countdown Display")
                .font(.system(size: 11, weight: .semibold))

            Picker("Countdown display mode", selection: countdownDisplayModeBinding) {
                ForEach(CountdownDisplayMode.allCases, id: \.rawValue) { mode in
                    Text(mode.displayName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: presetSettings.countdownDisplayMode) { newValue in
                guard selectedCountdownDisplayMode != newValue else { return }
                selectedCountdownDisplayMode = newValue
            }
        }
        .padding(8)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var notificationSettings: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notifications")
                .font(.system(size: 11, weight: .semibold))

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
        .padding(8)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func workMinutesBinding(for preset: Preset) -> Binding<Int> {
        Binding(
            get: { presetSettings.workMinutes(for: preset) },
            set: { presetSettings.setWorkMinutes($0, for: preset) }
        )
    }

    private func breakMinutesBinding(for preset: Preset) -> Binding<Int> {
        Binding(
            get: { presetSettings.breakMinutes(for: preset) },
            set: { presetSettings.setBreakMinutes($0, for: preset) }
        )
    }

    private func longBreakMinutesBinding(for preset: Preset) -> Binding<Int> {
        Binding(
            get: { presetSettings.longBreakMinutes(for: preset) },
            set: { presetSettings.setLongBreakMinutes($0, for: preset) }
        )
    }

    private var displayTargetBinding: Binding<DisplayTarget> {
        Binding(
            get: { selectedDisplayTarget },
            set: { selectedDisplayTarget = $0 }
        )
    }

    private var countdownDisplayModeBinding: Binding<CountdownDisplayMode> {
        Binding(
            get: { selectedCountdownDisplayMode },
            set: { newValue in
                selectedCountdownDisplayMode = newValue
                DispatchQueue.main.async {
                    presetSettings.setCountdownDisplayMode(newValue)
                }
            }
        )
    }

    private var roundsBeforeLongBreakBinding: Binding<Int> {
        Binding(
            get: { presetSettings.roundsBeforeLongBreak },
            set: { presetSettings.setRoundsBeforeLongBreak($0) }
        )
    }

    private var currentVersion: String {
        func getVersion(from bundle: Bundle) -> (String, String)? {
            guard let shortVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String,
                  let buildVersion = bundle.infoDictionary?["CFBundleVersion"] as? String
            else {
                return nil
            }
            return (shortVersion, buildVersion)
        }

        let appBundle = Bundle.main
        let fallbackBundle = Bundle(identifier: "com.productsway.oak.app") ?? Bundle(for: FocusSessionViewModel.self)

        if let (shortVersion, buildVersion) = getVersion(from: appBundle) {
            return "v\(shortVersion) (\(buildVersion))"
        } else if let (shortVersion, buildVersion) = getVersion(from: fallbackBundle) {
            return "v\(shortVersion) (\(buildVersion))"
        }

        return "v0.0.0 (0)"
    }

    private var validRangeDescription: String {
        let focusRange = "\(PresetSettingsStore.minWorkMinutes)-\(PresetSettingsStore.maxWorkMinutes)"
        let breakRange = "\(PresetSettingsStore.minBreakMinutes)-\(PresetSettingsStore.maxBreakMinutes)"
        let cycleRange = "\(PresetSettingsStore.minRoundsBeforeLongBreak)"
            + "-\(PresetSettingsStore.maxRoundsBeforeLongBreak)"
        return "Valid range: Focus \(focusRange) min, Break \(breakRange) min, Long cycle \(cycleRange) sessions"
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
