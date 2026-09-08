import SwiftUI

internal enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case sessions
    case notifications
    case shortcuts
    case advanced

    internal var id: String {
        rawValue
    }

    internal var title: String {
        switch self {
        case .general: "General"
        case .sessions: "Sessions"
        case .notifications: "Notifications"
        case .shortcuts: "Shortcuts"
        case .advanced: "Advanced"
        }
    }

    internal var accessibilityIdentifier: String {
        "settingsTab_\(rawValue)"
    }
}

internal struct SettingsTabNavigation: View {
    @Binding internal var selectedTab: SettingsTab
    internal let theme: AppTheme

    private var palette: ThemePalette {
        theme.palette
    }

    internal init(selectedTab: Binding<SettingsTab>, theme: AppTheme) {
        _selectedTab = selectedTab
        self.theme = theme
    }

    internal var body: some View {
        Picker("Settings section", selection: $selectedTab) {
            ForEach(SettingsTab.allCases) { tab in
                Text(tab.title)
                    .tag(tab)
                    .accessibilityIdentifier(tab.accessibilityIdentifier)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(palette.surface)
        .accessibilityIdentifier("settingsTabBar")
    }
}

internal enum SettingsWindowLayout {
    internal static let minimumWidth: CGFloat = 560
    internal static let idealWidth: CGFloat = 600
    internal static let minimumHeight: CGFloat = 360
    internal static let maximumHeight: CGFloat = 760
    internal static let fallbackScreenHeight: CGFloat = 900
    internal static let initialPageHeight: CGFloat = 500
    internal static let initialNavigationHeight: CGFloat = 52

    internal static func windowHeight(
        pageContentHeight: CGFloat,
        navigationHeight: CGFloat,
        screenHeight: CGFloat
    ) -> CGFloat {
        let screenBound = min(maximumHeight, screenHeight * 0.85)
        let maximum = max(minimumHeight, screenBound)
        return min(max(pageContentHeight + navigationHeight + 1, minimumHeight), maximum)
    }

    internal static func pageViewportHeight(windowHeight: CGFloat, navigationHeight: CGFloat) -> CGFloat {
        max(windowHeight - navigationHeight - 1, 0)
    }
}

internal struct SettingsPageHeightPreferenceKey: PreferenceKey {
    internal static let defaultValue: CGFloat = 0

    internal static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

internal struct SettingsNavigationHeightPreferenceKey: PreferenceKey {
    internal static let defaultValue: CGFloat = SettingsWindowLayout.initialNavigationHeight

    internal static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
