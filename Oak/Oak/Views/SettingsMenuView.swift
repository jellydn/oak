import AppKit
import SwiftUI

internal struct SettingsMenuView: View {
    @ObservedObject internal var presetSettings: PresetSettingsStore
    @ObservedObject internal var notificationService: NotificationService
    @ObservedObject internal var sparkleUpdater: SparkleUpdater
    @ObservedObject internal var keyboardShortcutService: KeyboardShortcutService
    internal var progressManager: ProgressManager?
    @State private var selectedDisplayTarget: DisplayTarget
    @State private var selectedCountdownDisplayMode: CountdownDisplayMode
    @State private var selectedTab = SettingsTab.general

    private var palette: ThemePalette {
        presetSettings.theme.palette
    }

    internal init(
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
    }

    internal var body: some View {
        TabView(selection: $selectedTab) {
            generalPage
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(SettingsTab.general)
                .accessibilityIdentifier("settingsTab_general")

            sessionsPage
                .tabItem { Label("Sessions", systemImage: "timer") }
                .tag(SettingsTab.sessions)
                .accessibilityIdentifier("settingsTab_sessions")

            notificationsPage
                .tabItem { Label("Notifications", systemImage: "bell") }
                .tag(SettingsTab.notifications)
                .accessibilityIdentifier("settingsTab_notifications")

            shortcutsPage
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
                .tag(SettingsTab.shortcuts)
                .accessibilityIdentifier("settingsTab_shortcuts")

            advancedPage
                .tabItem { Label("Advanced", systemImage: "slider.horizontal.3") }
                .tag(SettingsTab.advanced)
                .accessibilityIdentifier("settingsTab_advanced")
        }
        .foregroundColor(palette.foreground)
        .tint(palette.accent)
        .background(palette.background)
        .preferredColorScheme(palette.colorScheme)
        .task {
            await notificationService.refreshAuthorizationStatus()
        }
    }
}

private extension SettingsMenuView {
    func page(
        title: String,
        description: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title2.weight(.semibold))
                Text(description)
                    .font(.callout)
                    .foregroundColor(palette.secondaryForeground)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 16) {
                    content()
                }
                .padding(.top, 18)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .background(palette.background)
    }

    func settingsGroup(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(palette.divider, lineWidth: 1)
        }
    }

    func settingRow(
        _ title: String,
        description: String? = nil,
        @ViewBuilder control: () -> some View
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 16) {
                settingLabel(title, description: description)
                    .frame(minWidth: 180, maxWidth: .infinity, alignment: .leading)

                control()
                    .frame(width: 210, alignment: .trailing)
            }

            VStack(alignment: .leading, spacing: 10) {
                settingLabel(title, description: description)

                control()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    func settingLabel(_ title: String, description: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.body)

            if let description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(palette.secondaryForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    var generalPage: some View {
        page(title: "General", description: "Choose Oak's appearance and where the notch companion is shown.") {
            settingsGroup(title: "Appearance", systemImage: "paintpalette") {
                themePicker
            }

            settingsGroup(title: "Display", systemImage: "display") {
                if NSScreen.screens.count > 1 {
                    displayTargetPicker
                }
                countdownDisplayModePicker
                alwaysOnTopToggle
                if hasNotchedScreen {
                    showBelowNotchToggle
                }
            }
        }
    }

    var sessionsPage: some View {
        page(title: "Sessions", description: "Set session behavior and focus or break durations.") {
            settingsGroup(title: "Session Behavior", systemImage: "arrow.triangle.2.circlepath") {
                autoStartNextIntervalToggle
                longBreakCycleEditor
            }

            settingsGroup(title: "Presets", systemImage: "clock") {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 12) {
                        presetEditor(for: .short)
                        presetEditor(for: .long)
                    }

                    VStack(spacing: 12) {
                        presetEditor(for: .short)
                        presetEditor(for: .long)
                    }
                }

                Text(validRangeDescription)
                    .font(.caption)
                    .foregroundColor(palette.secondaryForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    var notificationsPage: some View {
        page(title: "Notifications", description: "Manage session alerts and completion sounds.") {
            settingsGroup(title: "Alerts", systemImage: "bell.badge") {
                NotificationSettingsView(
                    presetSettings: presetSettings,
                    notificationService: notificationService
                )
            }
        }
    }

    var shortcutsPage: some View {
        page(title: "Shortcuts", description: "Control sessions from the keyboard.") {
            settingsGroup(title: "Keyboard", systemImage: "keyboard") {
                KeyboardSettingsView(
                    keyboardShortcutService: keyboardShortcutService,
                    theme: presetSettings.theme
                )
            }
        }
    }

    var advancedPage: some View {
        page(title: "Advanced", description: "Back up data, manage updates, and find project information.") {
            settingsGroup(title: "Data", systemImage: "externaldrive") {
                DataSettingsView(progressManager: progressManager, theme: presetSettings.theme)
            }

            settingsGroup(title: "Updates", systemImage: "arrow.down.circle") {
                UpdateSettingsView(sparkleUpdater: sparkleUpdater, theme: presetSettings.theme)
            }

            settingsGroup(title: "Support", systemImage: "heart") {
                SupportSectionView(theme: presetSettings.theme)
            }

            settingsGroup(title: "About Oak", systemImage: "info.circle") {
                settingRow("Version") {
                    Text(currentVersion)
                        .foregroundColor(palette.secondaryForeground)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        applicationButtons
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        applicationButtons
                    }
                }
            }
        }
    }

    @ViewBuilder
    var applicationButtons: some View {
        Button("Reset to Defaults") {
            presetSettings.resetToDefault()
        }
        .buttonStyle(.bordered)

        Button("Quit Oak") {
            NSApplication.shared.terminate(nil)
        }
        .buttonStyle(.bordered)
        .help("Quit Oak")
    }

    func presetEditor(for preset: Preset) -> some View {
        PresetEditorView(
            presetSettings: presetSettings,
            title: presetSettings.displayName(for: preset),
            preset: preset
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var longBreakCycleEditor: some View {
        settingRow(
            "Long-break cycle",
            description: "Start a long break after this number of completed focus sessions."
        ) {
            Stepper(
                "\(presetSettings.roundsBeforeLongBreak) sessions",
                value: roundsBeforeLongBreakBinding,
                in: PresetSettingsStore.minRoundsBeforeLongBreak ... PresetSettingsStore.maxRoundsBeforeLongBreak
            )
            .frame(width: 130)
        }
    }

    var themePicker: some View {
        settingRow("Theme", description: "Changes colors and the matching light or dark control appearance.") {
            Picker(
                "Theme",
                selection: Binding(
                    get: { presetSettings.theme },
                    set: { presetSettings.setTheme($0) }
                )
            ) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.displayName)
                        .tag(theme)
                }
            }
            .labelsHidden()
            .frame(width: 210)
        }
        .accessibilityHint("Changes Oak colors throughout the app")
        .accessibilityIdentifier("themePicker")
    }

    var displayTargetPicker: some View {
        settingRow("Display", description: "The screen that shows the notch companion.") {
            Picker("Display", selection: displayTargetBinding) {
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
            .labelsHidden()
            .frame(width: 210)
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
    }

    var countdownDisplayModePicker: some View {
        settingRow("Countdown style", description: "Show the remaining time as digits or a progress ring.") {
            Picker("Countdown style", selection: countdownDisplayModeBinding) {
                ForEach(CountdownDisplayMode.allCases, id: \.rawValue) { mode in
                    Text(mode.displayName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 210)
            .onChange(of: presetSettings.countdownDisplayMode) { newValue in
                guard selectedCountdownDisplayMode != newValue else { return }
                selectedCountdownDisplayMode = newValue
            }
        }
    }

    var alwaysOnTopToggle: some View {
        settingRow("Always on top", description: "Keep the companion above other windows.") {
            Toggle(
                "Always on top",
                isOn: Binding(
                    get: { presetSettings.alwaysOnTop },
                    set: { presetSettings.setAlwaysOnTop($0) }
                )
            )
            .labelsHidden()
            .toggleStyle(.switch)
        }
    }

    var showBelowNotchToggle: some View {
        settingRow("Position", description: "Place the companion below the physical notch.") {
            Toggle(
                "Show below notch",
                isOn: Binding(
                    get: { presetSettings.showBelowNotch },
                    set: { presetSettings.setShowBelowNotch($0) }
                )
            )
            .labelsHidden()
            .toggleStyle(.switch)
        }
    }

    var autoStartNextIntervalToggle: some View {
        settingRow(
            "Auto-start next interval",
            description: "Start the next focus or break interval after 10 seconds."
        ) {
            Toggle(
                "Auto-start next interval",
                isOn: Binding(
                    get: { presetSettings.autoStartNextInterval },
                    set: { presetSettings.setAutoStartNextInterval($0) }
                )
            )
            .labelsHidden()
            .toggleStyle(.switch)
        }
    }

    var hasNotchedScreen: Bool {
        NSScreen.screens.contains { $0.hasNotch }
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

private enum SettingsTab: Hashable {
    case general
    case sessions
    case notifications
    case shortcuts
    case advanced
}
