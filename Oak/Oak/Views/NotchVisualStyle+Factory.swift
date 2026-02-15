import SwiftUI

internal extension NotchVisualStyle {
    /// Creates a unified visual style for all UI states.
    /// Uses a clean, minimal style without borders or shadows.
    static func make(
        isExpanded: Bool,
        isSessionComplete: Bool,
        isInsideNotch: Bool
    ) -> NotchVisualStyle {
        NotchVisualStyle(
            isInsideNotchStyle: isInsideNotch,
            backgroundColors: [
                Color.black.opacity(0.98),
                Color(red: 0.01, green: 0.01, blue: 0.02).opacity(0.99)
            ],
            borderColor: .clear,
            borderWidth: 0,
            shadowColor: .clear,
            shadowRadius: 0,
            dividerColor: Color.white.opacity(0.26),
            neutralControlOpacity: 0.17,
            toggleControlOpacity: 0.20,
            presetCapsuleOpacity: 0.18,
            cornerRadius: 12
        )
    }
}
