import SwiftUI

internal enum AppTheme: String, CaseIterable, Identifiable {
    case oak
    case kanagawa
    case dracula
    case tokyoNight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oak: "Oak"
        case .kanagawa: "Kanagawa"
        case .dracula: "Dracula"
        case .tokyoNight: "Tokyo Night"
        }
    }

    var palette: ThemePalette {
        switch self {
        case .oak:
            ThemePalette(
                background: Self.color(0x010105),
                surface: Self.color(0x030305),
                foreground: .white,
                accent: Self.color(0x66A7FF),
                success: Self.color(0x69D17D),
                warning: Self.color(0xF4AA4F),
                error: Self.color(0xFF666C),
                purple: Self.color(0xB895F3),
                pink: Self.color(0xF080B5),
                yellow: Self.color(0xF4D76D)
            )
        case .kanagawa:
            // Wave is the default Kanagawa variant, so it is the least surprising unqualified palette.
            ThemePalette(
                background: Self.color(0x1F1F28),
                surface: Self.color(0x2A2A37),
                foreground: Self.color(0xDCD7BA),
                accent: Self.color(0x7E9CD8),
                success: Self.color(0x98BB6C),
                warning: Self.color(0xFF9E3B),
                error: Self.color(0xE82424),
                purple: Self.color(0x957FB8),
                pink: Self.color(0xD27E99),
                yellow: Self.color(0xE6C384)
            )
        case .dracula:
            ThemePalette(
                background: Self.color(0x282A36),
                surface: Self.color(0x44475A),
                foreground: Self.color(0xF8F8F2),
                accent: Self.color(0x8BE9FD),
                success: Self.color(0x50FA7B),
                warning: Self.color(0xFFB86C),
                error: Self.color(0xFF5555),
                purple: Self.color(0xBD93F9),
                pink: Self.color(0xFF79C6),
                yellow: Self.color(0xF1FA8C)
            )
        case .tokyoNight:
            // Moon is Tokyo Night's current default and provides stronger compact-UI contrast than Night.
            ThemePalette(
                background: Self.color(0x222436),
                surface: Self.color(0x2F334D),
                foreground: Self.color(0xC8D3F5),
                accent: Self.color(0x82AAFF),
                success: Self.color(0xC3E88D),
                warning: Self.color(0xFF966C),
                error: Self.color(0xC53B53),
                purple: Self.color(0xFCA7EA),
                pink: Self.color(0xC099FF),
                yellow: Self.color(0xFFC777)
            )
        }
    }

    private static func color(_ hex: UInt32) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

internal struct ThemePalette {
    let background: Color
    let surface: Color
    let foreground: Color
    let accent: Color
    let success: Color
    let warning: Color
    let error: Color
    let purple: Color
    let pink: Color
    let yellow: Color

    var secondaryForeground: Color { foreground.opacity(0.72) }
    var subtleForeground: Color { foreground.opacity(0.60) }
    var controlBackground: Color { foreground.opacity(0.16) }
    var selectedBackground: Color { accent.opacity(0.22) }
    var divider: Color { foreground.opacity(0.24) }
    var confettiColors: [Color] { [success, accent, warning, pink, purple, yellow, error] }
}
