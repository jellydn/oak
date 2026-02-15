import Foundation

/// Shared layout constants for the notch companion UI.
/// These values define the window dimensions and ensure consistency
/// between NotchCompanionView and NotchWindowController.
internal enum NotchLayout {
    /// Height of the notch window (constant for both collapsed and expanded states)
    static let height: CGFloat = 33

    /// Width of the collapsed notch window
    static let collapsedWidth: CGFloat = 120

    /// Width of the expanded notch window
    static let expandedWidth: CGFloat = 320

    /// Width multiplier for compact mode inside a physical notch.
    /// 2.5x provides enough space for "Focus" label + play button + expand toggle.
    private static let insideNotchCompactMultiplier: CGFloat = 2.5

    /// Width multiplier for expanded mode inside a physical notch.
    /// 4x provides space for timer display, session type, and all control buttons.
    private static let insideNotchExpandedMultiplier: CGFloat = 4

    /// Width used for compact mode when showing inside a physical notch
    static let insideNotchCollapsedWidth: CGFloat = collapsedWidth * insideNotchCompactMultiplier

    /// Width used for expanded mode when showing inside a physical notch
    static let insideNotchExpandedWidth: CGFloat = collapsedWidth * insideNotchExpandedMultiplier
}
