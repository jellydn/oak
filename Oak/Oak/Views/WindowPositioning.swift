import AppKit
import CoreGraphics

/// Consolidated window positioning calculations extracted from NotchWindowController.
/// Centralizes frame math, Y-position, width selection, and frame-delta checks.
@MainActor
internal enum WindowPositioning {
    /// Calculate Y position for notch-first UI.
    static func calculateYPosition(
        for screen: NSScreen?,
        height: CGFloat,
        alwaysOnTop: Bool,
        showBelowNotch: Bool = false
    ) -> CGFloat {
        guard let screen else { return 0 }

        if screen.hasNotch {
            if showBelowNotch {
                return screen.visibleFrame.maxY - height
            } else {
                let notchHeight = screen.safeAreaInsets.top
                if height < notchHeight {
                    return screen.frame.maxY - notchHeight
                }
                return screen.frame.maxY - height
            }
        }

        if alwaysOnTop {
            return screen.visibleFrame.maxY - height
        }
        return screen.frame.maxY - height
    }

    /// Determine collapsed and expanded widths for the given screen.
    static func widths(for screen: NSScreen?, showBelowNotch: Bool) -> (collapsed: CGFloat, expanded: CGFloat) {
        let isInsideNotch = screen?.hasNotch == true && !showBelowNotch
        if isInsideNotch {
            return (
                collapsed: NotchLayout.insideNotchCollapsedWidth,
                expanded: NotchLayout.insideNotchExpandedWidth
            )
        }
        return (collapsed: NotchLayout.collapsedWidth, expanded: NotchLayout.expandedWidth)
    }

    /// Compute initial widths based on the preset settings.
    static func initialWidths(for settings: PresetSettingsStore) -> (collapsed: CGFloat, expanded: CGFloat) {
        let initialScreen = NSScreen.screen(
            for: settings.displayTarget,
            preferredDisplayID: settings.preferredDisplayID(for: settings.displayTarget)
        )
        return widths(for: initialScreen, showBelowNotch: settings.showBelowNotch)
    }

    /// Build the full window frame for a given state.
    static func calculateFrame(
        screen: NSScreen?,
        width: CGFloat,
        height: CGFloat,
        alwaysOnTop: Bool,
        showBelowNotch: Bool
    ) -> NSRect {
        let screenFrame = screen?.frame ?? .zero
        let xPosition = screenFrame.midX - (width / 2)
        let yPosition = calculateYPosition(
            for: screen,
            height: height,
            alwaysOnTop: alwaysOnTop,
            showBelowNotch: showBelowNotch
        )
        return NSRect(x: xPosition, y: yPosition, width: width, height: height)
    }

    /// Check whether a frame update should actually be applied (avoids redundant work).
    static func shouldApplyFrameUpdate(
        current: NSRect,
        target: NSRect,
        forceReposition: Bool
    ) -> Bool {
        if forceReposition {
            return true
        }

        return abs(current.minX - target.minX) > 0.5
            || abs(current.minY - target.minY) > 0.5
            || abs(current.width - target.width) > 0.5
            || abs(current.height - target.height) > 0.5
    }
}
