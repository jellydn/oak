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
    ///
    /// Tuned to avoid right-edge cutoff for expanded controls when rendered
    /// inside the notch panel.
    static let expandedWidth: CGFloat = 344
}
