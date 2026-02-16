import AppKit
import SwiftUI

internal struct SettingsMenuView: View {
    @ObservedObject var presetSettings: PresetSettingsStore
    @ObservedObject var notificationService: NotificationService
    @ObservedObject var sparkleUpdater: SparkleUpdater
    @State private var selectedDisplayTarget: DisplayTarget
    @State private var selectedCountdownDisplayMode: CountdownDisplayMode

    init(
        presetSettings: PresetSettingsStore,
        notificationService: NotificationService,
        sparkleUpdater: SparkleUpdater
    ) {
        self.presetSettings = presetSettings
        self.notificationService = notificationService
        self.sparkleUpdater = sparkleUpdater
        _selectedDisplayTarget = State(initialValue: presetSettings.displayTarget)
        _selectedCountdownDisplayMode = State(initialValue: presetSettings.countdownDisplayMode)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow

            Divider()

            section(title: "Display") {
                if NSScreen.screens.count > 1 {
                    displayTargetPicker
                }
                countdownDisplayModePicker
                alwaysOnTopToggle
                if hasNotchedScreen {
                    showBelowNotchToggle
                }
            }

            section(title: "Session Presets") {
                autoStartNextIntervalToggle
                longBreakCycleEditor
                presetEditor(title: presetSettings.displayName(for: .short), preset: .short)
                presetEditor(title: presetSettings.displayName(for: .long), preset: .long)
            }

            section(title: "Notifications") {
                NotificationSettingsView(
                    presetSettings: presetSettings,
                    notificationService: notificationService
                )
            }

            section(title: "Updates") {
                UpdateSettingsView(sparkleUpdater: sparkleUpdater)
            }

            section(title: "Support") {
                SupportSectionView()
            }

            Divider()

            Text(validRangeDescription)
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack {
                Button("Reset to defaults") {
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
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Settings")
                    .font(.headline)
                Text("Focus presets, display, and notifications.")
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

    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
            content()
        }
    }

    private func presetEditor(title: String, preset: Preset) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium))

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
    }

    private var longBreakCycleEditor: some View {
        Stepper(
            value: roundsBeforeLongBreakBinding,
            in: PresetSettingsStore.minRoundsBeforeLongBreak ... PresetSettingsStore.maxRoundsBeforeLongBreak
        ) {
            Text("Long break every \(presetSettings.roundsBeforeLongBreak) focus sessions")
                .font(.caption)
        }
    }

    private var displayTargetPicker: some View {
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

    private var countdownDisplayModePicker: some View {
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

    private var alwaysOnTopToggle: some View {
        Toggle(
            "Always on top",
            isOn: Binding(
                get: { presetSettings.alwaysOnTop },
                set: { presetSettings.setAlwaysOnTop($0) }
            )
        )
        .font(.caption)
    }

    private var showBelowNotchToggle: some View {
        Toggle(
            "Show below notch",
            isOn: Binding(
                get: { presetSettings.showBelowNotch },
                set: { presetSettings.setShowBelowNotch($0) }
            )
        )
        .font(.caption)
    }

    private var autoStartNextIntervalToggle: some View {
        Toggle(
            "Auto-start next interval (10s delay)",
            isOn: Binding(
                get: { presetSettings.autoStartNextInterval },
                set: { presetSettings.setAutoStartNextInterval($0) }
            )
        )
        .font(.caption)
    }

    private var hasNotchedScreen: Bool {
        NSScreen.screens.contains { $0.hasNotch }
    }
}

private extension SettingsMenuView {
    func workMinutesBinding(for preset: Preset) -> Binding<Int> {
        Binding(
            get: { presetSettings.workMinutes(for: preset) },
            set: { presetSettings.setWorkMinutes($0, for: preset) }
        )
    }

    func breakMinutesBinding(for preset: Preset) -> Binding<Int> {
        Binding(
            get: { presetSettings.breakMinutes(for: preset) },
            set: { presetSettings.setBreakMinutes($0, for: preset) }
        )
    }

    func longBreakMinutesBinding(for preset: Preset) -> Binding<Int> {
        Binding(
            get: { presetSettings.longBreakMinutes(for: preset) },
            set: { presetSettings.setLongBreakMinutes($0, for: preset) }
        )
    }

    var displayTargetBinding: Binding<DisplayTarget> {
        Binding(
            get: { selectedDisplayTarget },
            set: { selectedDisplayTarget = $0 }
        )
    }

    var countdownDisplayModeBinding: Binding<CountdownDisplayMode> {
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

    var roundsBeforeLongBreakBinding: Binding<Int> {
        Binding(
            get: { presetSettings.roundsBeforeLongBreak },
            set: { presetSettings.setRoundsBeforeLongBreak($0) }
        )
    }

    var currentVersion: String {
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

    var validRangeDescription: String {
        let focusRange = "\(PresetSettingsStore.minWorkMinutes)-\(PresetSettingsStore.maxWorkMinutes)"
        let breakRange = "\(PresetSettingsStore.minBreakMinutes)-\(PresetSettingsStore.maxBreakMinutes)"
        let cycleRange = "\(PresetSettingsStore.minRoundsBeforeLongBreak)"
            + "-\(PresetSettingsStore.maxRoundsBeforeLongBreak)"
        return "Valid range: Focus \(focusRange) min, Break \(breakRange) min, Long cycle \(cycleRange) sessions"
    }
}
