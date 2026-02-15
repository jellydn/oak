import SwiftUI

internal extension NotchVisualStyle {
    /// Creates a visual style based on the current UI state.
    /// - Parameters:
    ///   - isExpanded: Whether the UI is in expanded mode
    ///   - isSessionComplete: Whether the current focus session is complete
    ///   - isInsideNotch: Whether the UI should adapt to display inside a physical notch
    static func make(
        isExpanded: Bool,
        isSessionComplete: Bool,
        isInsideNotch: Bool
    ) -> NotchVisualStyle {
        if isInsideNotch && !isExpanded {
            return insideNotchCompact(isSessionComplete: isSessionComplete)
        }
        return standard(isExpanded: isExpanded, isSessionComplete: isSessionComplete)
    }

    private static func insideNotchCompact(isSessionComplete: Bool) -> NotchVisualStyle {
        NotchVisualStyle(
            isInsideNotchStyle: true,
            backgroundColors: [
                Color.black.opacity(0.98),
                Color(red: 0.01, green: 0.01, blue: 0.02).opacity(0.99)
            ],
            borderColor: isSessionComplete ? Color.green.opacity(0.60) : Color.white.opacity(0.30),
            borderWidth: isSessionComplete ? 1.6 : 1.2,
            shadowColor: Color.black.opacity(0.44),
            shadowRadius: 6,
            dividerColor: Color.white.opacity(0.26),
            neutralControlOpacity: 0.17,
            toggleControlOpacity: 0.20,
            presetCapsuleOpacity: 0.18,
            cornerRadius: 12
        )
    }

    private static func standard(isExpanded: Bool, isSessionComplete: Bool) -> NotchVisualStyle {
        if isExpanded {
            return NotchVisualStyle(
                isInsideNotchStyle: false,
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
            isInsideNotchStyle: false,
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
