import AppKit
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

    private var palette: ThemePalette {
        theme.palette
    }

    internal init(selectedTab: Binding<SettingsTab>, theme: AppTheme) {
        _selectedTab = selectedTab
        self.theme = theme
    }

    internal var body: some View {
        SettingsSegmentedControl(selectedTab: $selectedTab, theme: theme)
            .frame(height: 28)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, SettingsWindowLayout.navigationHorizontalPadding)
            .padding(.vertical, 12)
            .background(palette.surface)
            .accessibilityIdentifier("settingsTabBar")
    }
}

internal struct SettingsSegmentedControl: NSViewRepresentable {
    @Binding internal var selectedTab: SettingsTab
    internal let theme: AppTheme

    internal init(selectedTab: Binding<SettingsTab>, theme: AppTheme) {
        _selectedTab = selectedTab
        self.theme = theme
    }

    internal func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    internal func makeNSView(context: Context) -> NSSegmentedControl {
        let control = Self.makeControl(
            target: context.coordinator,
            action: #selector(Coordinator.selectionChanged(_:))
        )
        update(control)
        return control
    }

    internal func updateNSView(_ control: NSSegmentedControl, context: Context) {
        context.coordinator.parent = self
        update(control)
    }

    internal func sizeThatFits(
        _ proposal: ProposedViewSize,
        nsView _: NSSegmentedControl,
        context _: Context
    ) -> CGSize? {
        guard let width = proposal.width else { return nil }
        return CGSize(width: width, height: 28)
    }

    internal static func makeControl(target: AnyObject?, action: Selector?) -> NSSegmentedControl {
        let images = SettingsTab.allCases.map { tab in
            NSImage(systemSymbolName: tab.symbolName, accessibilityDescription: tab.title)!
        }
        let control = NSSegmentedControl(
            images: images,
            trackingMode: .selectOne,
            target: target,
            action: action
        )
        control.segmentDistribution = .fillEqually
        control.segmentStyle = .rounded
        control.setAccessibilityLabel("Settings section")
        control.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        control.setContentHuggingPriority(.defaultLow, for: .horizontal)

        for (index, tab) in SettingsTab.allCases.enumerated() {
            control.setWidth(0, forSegment: index)
            control.setImageScaling(.scaleProportionallyDown, forSegment: index)
            control.setToolTip(tab.title, forSegment: index)
        }
        return control
    }

    private func update(_ control: NSSegmentedControl) {
        control.selectedSegment = SettingsTab.allCases.firstIndex(of: selectedTab) ?? 0
        control.selectedSegmentBezelColor = NSColor(theme.palette.accent)
    }

    @MainActor
    internal final class Coordinator: NSObject {
        internal var parent: SettingsSegmentedControl

        internal init(parent: SettingsSegmentedControl) {
            self.parent = parent
        }

        @objc internal func selectionChanged(_ control: NSSegmentedControl) {
            guard SettingsTab.allCases.indices.contains(control.selectedSegment) else { return }
            parent.selectedTab = SettingsTab.allCases[control.selectedSegment]
        }
    }
}

internal enum SettingsWindowLayout {
    internal static let navigationHorizontalPadding: CGFloat = 20
    internal static let minimumTabSegmentWidth: CGFloat = 104
    internal static let minimumWidth = navigationHorizontalPadding * 2
        + minimumTabSegmentWidth * CGFloat(SettingsTab.allCases.count)
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
