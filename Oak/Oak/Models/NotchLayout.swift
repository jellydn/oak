import Foundation

/// Shared layout constants for the notch companion UI.
/// These values define the window dimensions and ensure consistency
/// between NotchCompanionView and NotchWindowController.
internal enum NotchLayout {
    /// Height of the notch window (constant for both collapsed and expanded states)
    static let height: CGFloat = 33

    /// Width of the collapsed notch window
    static let collapsedWidth: CGFloat = 144

    /// Width of the expanded notch window
    static let expandedWidth: CGFloat = 372
}
