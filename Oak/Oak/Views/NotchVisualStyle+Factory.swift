import SwiftUI

internal extension NotchVisualStyle {
    static func make(isInsideNotch: Bool) -> NotchVisualStyle {
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
