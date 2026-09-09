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

    internal var symbolName: String {
        switch self {
        case .general: "gearshape"
        case .sessions: "timer"
        case .notifications: "bell"
        case .shortcuts: "keyboard"
        case .advanced: "slider.horizontal.3"
        }
    }

    internal var accessibilityIdentifier: String {
        "settingsTab_\(rawValue)"
    }
}

internal struct SettingsTabNavigation: View {
    @Binding internal var selectedTab: SettingsTab
    internal let theme: AppTheme
    @FocusState private var focusedTab: SettingsTab?
    @State private var hoveredTab: SettingsTab?

    private var palette: ThemePalette {
        theme.palette
    }

    internal init(selectedTab: Binding<SettingsTab>, theme: AppTheme) {
        _selectedTab = selectedTab
        self.theme = theme
    }

    internal var body: some View {
        HStack(spacing: SettingsWindowLayout.tabSpacing) {
            ForEach(SettingsTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Image(systemName: tab.symbolName)
                        .accessibilityHidden(true)
                }
                .buttonStyle(
                    SettingsTabButtonStyle(
                        isSelected: selectedTab == tab,
                        isHovered: hoveredTab == tab,
                        isFocused: focusedTab == tab,
                        palette: palette
                    )
                )
                .focused($focusedTab, equals: tab)
                .help(tab.title)
                .accessibilityLabel(Text(tab.title))
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                .accessibilityIdentifier(tab.accessibilityIdentifier)
                .onHover { isHovered in
                    if isHovered {
                        hoveredTab = tab
                    } else if hoveredTab == tab {
                        hoveredTab = nil
                    }
                }
            }
        }
        .padding(SettingsWindowLayout.tabContainerPadding)
        .background(palette.controlBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onMoveCommand(perform: moveSelection)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, SettingsWindowLayout.navigationHorizontalPadding)
        .padding(.vertical, 12)
        .background(palette.surface)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Settings sections")
        .accessibilityIdentifier("settingsTabBar")
    }

    private func moveSelection(_ direction: MoveCommandDirection) {
        guard let currentIndex = SettingsTab.allCases.firstIndex(of: focusedTab ?? selectedTab) else { return }
        let nextIndex: Int
        switch direction {
        case .left:
            nextIndex = max(currentIndex - 1, SettingsTab.allCases.startIndex)
        case .right:
            nextIndex = min(currentIndex + 1, SettingsTab.allCases.index(before: SettingsTab.allCases.endIndex))
        default:
            return
        }
        let nextTab = SettingsTab.allCases[nextIndex]
        selectedTab = nextTab
        focusedTab = nextTab
    }
}

internal struct SettingsTabButtonStyle: ButtonStyle {
    internal let isSelected: Bool
    internal let isHovered: Bool
    internal let isFocused: Bool
    internal let palette: ThemePalette

    internal func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? palette.prominentSelectedForeground : palette.foreground)
            .frame(maxWidth: .infinity, minHeight: SettingsWindowLayout.tabHeight)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? palette.prominentSelectedBackground : .clear)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(stateOutlineColor, lineWidth: stateOutlineWidth)
            }
            .contentShape(Rectangle())
            // Geometry gives press feedback without weakening icon contrast.
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }

    private var stateOutlineColor: Color {
        if isSelected {
            return palette.prominentSelectedForeground
        }
        return palette.accent
    }

    private var stateOutlineWidth: CGFloat {
        if isFocused {
            return 2
        }
        return isHovered ? 1 : 0
    }
}

internal enum SettingsWindowLayout {
    internal static let navigationHorizontalPadding: CGFloat = 20
    internal static let minimumContentWidth: CGFloat = 520
    internal static let tabSpacing: CGFloat = 4
    internal static let tabContainerPadding: CGFloat = 3
    internal static let tabHeight: CGFloat = 28
    internal static let minimumWidth = navigationHorizontalPadding * 2 + minimumContentWidth
    internal static let idealWidth: CGFloat = 600
    internal static let minimumHeight: CGFloat = 360
    internal static let maximumHeight: CGFloat = 760
    internal static let fallbackScreenHeight: CGFloat = 900
    internal static let initialPageHeight: CGFloat = 500
    internal static let initialNavigationHeight: CGFloat = 52

    internal static func tabItemWidth(containerWidth: CGFloat) -> CGFloat {
        let navigationWidth = max(containerWidth - navigationHorizontalPadding * 2, 0)
        let itemWidth = navigationWidth - tabContainerPadding * 2
            - tabSpacing * CGFloat(SettingsTab.allCases.count - 1)
        return max(itemWidth / CGFloat(SettingsTab.allCases.count), 0)
    }

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
