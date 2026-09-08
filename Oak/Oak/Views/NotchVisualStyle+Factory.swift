import SwiftUI

internal extension NotchVisualStyle {
    static func make(theme: AppTheme, isInsideNotch: Bool) -> NotchVisualStyle {
        let palette = theme.palette
        return NotchVisualStyle(
            isInsideNotchStyle: isInsideNotch,
            backgroundColors: [
                palette.background,
                palette.surface.opacity(0.92)
            ],
            borderColor: .clear,
            borderWidth: 0,
            shadowColor: .clear,
            shadowRadius: 0,
            dividerColor: palette.divider,
            neutralControlOpacity: 0.17,
            toggleControlOpacity: 0.20,
            presetCapsuleOpacity: 0.18,
            cornerRadius: 12
        )
    }
}
