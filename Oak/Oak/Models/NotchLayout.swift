import Foundation

/// Shared layout constants for the notch companion window
enum NotchLayout {
    /// Content width in collapsed state (view dimensions)
    static let contentWidth: CGFloat = 132
    
    /// Content width in expanded state (view dimensions)
    static let contentExpandedWidth: CGFloat = 360
    
    /// Window padding added around content
    static let windowPadding: CGFloat = 12
    
    /// Window width in collapsed state (content + padding)
    static let collapsedWidth: CGFloat = contentWidth + windowPadding
    
    /// Window width in expanded state (content + padding)
    static let expandedWidth: CGFloat = contentExpandedWidth + windowPadding
    
    /// Height of the notch window/view
    static let height: CGFloat = 33
}
