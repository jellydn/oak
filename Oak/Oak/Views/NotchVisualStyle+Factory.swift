import SwiftUI

internal extension NotchVisualStyle {
    static func make(isExpanded: Bool, isSessionComplete: Bool) -> NotchVisualStyle {
        if isExpanded {
            return NotchVisualStyle(
                backgroundColors: [
                    Color(red: 0.14, green: 0.16, blue: 0.20).opacity(0.92),
                    Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.96)
                ],
                borderColor: isSessionComplete ? Color.green.opacity(0.45) : Color.white.opacity(0.16),
                borderWidth: isSessionComplete ? 1.4 : 1,
                shadowColor: Color.black.opacity(0.30),
                shadowRadius: 12,
                dividerColor: Color.white.opacity(0.15),
                neutralControlOpacity: 0.08,
                toggleControlOpacity: 0.08,
                presetCapsuleOpacity: 0.08,
                cornerRadius: 15
            )
        }

        return NotchVisualStyle(
            backgroundColors: [
                Color(red: 0.04, green: 0.05, blue: 0.07).opacity(0.94),
                Color.black.opacity(0.98)
            ],
            borderColor: isSessionComplete ? Color.green.opacity(0.55) : Color.white.opacity(0.24),
            borderWidth: isSessionComplete ? 1.5 : 1.1,
            shadowColor: Color.black.opacity(0.38),
            shadowRadius: 8,
            dividerColor: Color.white.opacity(0.22),
            neutralControlOpacity: 0.14,
            toggleControlOpacity: 0.16,
            presetCapsuleOpacity: 0.14,
            cornerRadius: 13
        )
    }
}
