import AppKit
import SwiftUI

internal struct SettingsMenuView: View {
    @ObservedObject var presetSettings: PresetSettingsStore
    @ObservedObject var notificationService: NotificationService
    @ObservedObject var sparkleUpdater: SparkleUpdater
    @ObservedObject var keyboardShortcutService: KeyboardShortcutService
    var progressManager: ProgressManager?
    @State private var selectedDisplayTarget: DisplayTarget
    @State private var selectedCountdownDisplayMode: CountdownDisplayMode
    @State private var localKeyboardConfig: KeyboardShortcutConfig

    init(
        presetSettings: PresetSettingsStore,
        notificationService: NotificationService,
        sparkleUpdater: SparkleUpdater,
        keyboardShortcutService: KeyboardShortcutService = KeyboardShortcutService(),
        progressManager: ProgressManager? = nil
    ) {
        self.presetSettings = presetSettings
        self.notificationService = notificationService
        self.sparkleUpdater = sparkleUpdater
        self.keyboardShortcutService = keyboardShortcutService
        self.progressManager = progressManager
        _selectedDisplayTarget = State(initialValue: presetSettings.displayTarget)
        _selectedCountdownDisplayMode = State(initialValue: presetSettings.countdownDisplayMode)
        _localKeyboardConfig = State(initialValue: keyboardShortcutService.currentConfig)
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
                PresetEditorView(
                    presetSettings: presetSettings,
                    title: presetSettings.displayName(for: .short),
                    preset: .short
                )
                PresetEditorView(
                    presetSettings: presetSettings,
                    title: presetSettings.displayName(for: .long),
                    preset: .long
                )
            }

            section(title: "Notifications") {
                NotificationSettingsView(
                    presetSettings: presetSettings,
                    notificationService: notificationService
                )
            }

            section(title: "Keyboard") {
                keyboardSettingsSection
            }

            section(title: "Data") {
                dataSection
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

    // MARK: - Keyboard Settings

    var keyboardSettingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(
                "Enable keyboard shortcuts",
                isOn: Binding(
                    get: { localKeyboardConfig.enabled },
                    set: { newValue in
                        var updated = localKeyboardConfig
                        updated.enabled = newValue
                        localKeyboardConfig = updated
                        keyboardShortcutService.updateConfig(updated)
                    }
                )
            )
            .font(.caption)
            .help("Space to start/pause, Escape to reset. Works when Oak is active.")

            if localKeyboardConfig.enabled {
                VStack(alignment: .leading, spacing: 4) {
                    let toggleShortcut = localKeyboardConfig.shortcuts[.toggleSession]
                        ?? KeyboardShortcutAction.toggleSession.defaultKey
                    shortcutRow(action: .toggleSession, shortcut: toggleShortcut)
                    let resetShortcut = localKeyboardConfig.shortcuts[.resetSession]
                        ?? KeyboardShortcutAction.resetSession.defaultKey
                    shortcutRow(action: .resetSession, shortcut: resetShortcut)
                }
                .padding(.leading, 16)

                Toggle(
                    "Enable global hotkeys",
                    isOn: Binding(
                        get: { localKeyboardConfig.globalHotkeysEnabled },
                        set: { newValue in
                            var updated = localKeyboardConfig
                            updated.globalHotkeysEnabled = newValue
                            localKeyboardConfig = updated
                            keyboardShortcutService.updateConfig(updated)
                        }
                    )
                )
                .font(.caption)
                .help("Requires Accessibility permission in System Settings.")
            }
        }
    }

    private func shortcutRow(action: KeyboardShortcutAction, shortcut: KeyEquivalent) -> some View {
        HStack(spacing: 8) {
            Text(shortcut.displayString)
                .font(.caption.monospaced())
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
            Text(action.displayName)
                .font(.caption)
            Spacer()
        }
    }

    // MARK: - Data Export / Import

    var dataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Back up or restore your progress data.")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Button("Export JSON") {
                    exportJSON()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(progressManager == nil)

                Button("Export CSV") {
                    exportCSV()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(progressManager == nil)

                Button("Import") {
                    importData()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(progressManager == nil)
            }
        }
    }

    private func exportJSON() {
        guard let manager = progressManager,
              let data = manager.exportJSON()
        else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "oak-progress-\(dateStamp()).json"
        panel.allowedContentTypes = [.json]
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? data.write(to: url)
            }
        }
    }

    private func exportCSV() {
        guard let manager = progressManager else { return }
        let csv = manager.exportCSV()
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "oak-progress-\(dateStamp()).csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? csv.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    private func importData() {
        guard let manager = progressManager else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.begin { response in
            if response == .OK, let url = panel.url, let data = try? Data(contentsOf: url) {
                let count = manager.importRecords(from: data)
                if count > 0 {
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = "Import complete"
                        alert.informativeText = "Imported \(count) day(s) of progress data."
                        alert.runModal()
                    }
                }
            }
        }
    }

    private func dateStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
