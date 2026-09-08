import SwiftUI

internal struct KeyboardSettingsView: View {
    @ObservedObject internal var keyboardShortcutService: KeyboardShortcutService
    internal let theme: AppTheme
    @State private var localConfig: KeyboardShortcutConfig

    private var palette: ThemePalette { theme.palette }

    internal init(keyboardShortcutService: KeyboardShortcutService, theme: AppTheme) {
        self.keyboardShortcutService = keyboardShortcutService
        self.theme = theme
        _localConfig = State(initialValue: keyboardShortcutService.currentConfig)
    }

    internal var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            toggleRow(
                "Keyboard shortcuts",
                description: "Use Space to start or pause and Escape to reset.",
                isOn: Binding(
                    get: { localConfig.enabled },
                    set: { updateConfig(\.enabled, to: $0) }
                )
            )
            .help("Works when Oak is active.")

            if localConfig.enabled {
                VStack(alignment: .leading, spacing: 6) {
                    shortcutRow(
                        action: .toggleSession,
                        shortcut: localConfig.shortcuts[.toggleSession]
                            ?? KeyboardShortcutAction.toggleSession.defaultKey
                    )
                    shortcutRow(
                        action: .resetSession,
                        shortcut: localConfig.shortcuts[.resetSession]
                            ?? KeyboardShortcutAction.resetSession.defaultKey
                    )
                }
                .padding(10)
                .background(palette.controlBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                toggleRow(
                    "Global hotkeys",
                    description: "Control Oak when another app is active. Requires Accessibility permission.",
                    isOn: Binding(
                        get: { localConfig.globalHotkeysEnabled },
                        set: { updateConfig(\.globalHotkeysEnabled, to: $0) }
                    )
                )
            }
        }
    }

    private func toggleRow(_ title: String, description: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(description)
                    .font(.caption)
                    .foregroundColor(palette.secondaryForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)

            Spacer(minLength: 12)

            Toggle(title, isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }

    private func shortcutRow(action: KeyboardShortcutAction, shortcut: KeyEquivalent) -> some View {
        HStack(spacing: 10) {
            Text(action.displayName)
                .font(.callout)

            Spacer()

            Text(shortcut.displayString)
                .font(.caption.monospaced())
                .foregroundColor(palette.secondaryForeground)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
    }

    private func updateConfig(_ keyPath: WritableKeyPath<KeyboardShortcutConfig, Bool>, to value: Bool) {
        var updatedConfig = localConfig
        updatedConfig[keyPath: keyPath] = value
        localConfig = updatedConfig
        keyboardShortcutService.updateConfig(updatedConfig)
    }
}
