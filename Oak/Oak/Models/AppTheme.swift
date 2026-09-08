import SwiftUI

internal enum AppTheme: String, CaseIterable, Identifiable {
    case oak
    case kanagawa
    case kanagawaLotus
    case dracula
    case alucard
    case tokyoNight
    case tokyoNightDay

    internal var id: String { rawValue }

    internal var displayName: String {
        switch self {
        case .oak: "Oak"
        case .kanagawa: "Kanagawa"
        case .kanagawaLotus: "Kanagawa Lotus"
        case .dracula: "Dracula"
        case .alucard: "Alucard (Dracula Light)"
        case .tokyoNight: "Tokyo Night"
        case .tokyoNightDay: "Tokyo Night Day"
        }
    }

    internal var palette: ThemePalette {
        switch self {
        case .oak:
            ThemePalette(
                colorScheme: .dark,
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
                colorScheme: .dark,
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
        case .kanagawaLotus:
            // Oak uses deeper Lotus tokens where its editor defaults are too faint for compact controls.
            ThemePalette(
                colorScheme: .light,
                background: Self.color(0xF2ECBC),
                surface: Self.color(0xE5DDB0),
                foreground: Self.color(0x43436C),
                accent: Self.color(0x4D699B),
                success: Self.color(0x597B75),
                warning: Self.color(0x77713F),
                error: Self.color(0xC84053),
                purple: Self.color(0x624C83),
                pink: Self.color(0xB35B79),
                yellow: Self.color(0x77713F)
            )
        case .dracula:
            ThemePalette(
                colorScheme: .dark,
                background: Self.color(0x282A36),
                surface: Self.color(0x44475A),
                foreground: Self.color(0xF8F8F2),
                accent: Self.color(0x8BE9FD),
                success: Self.color(0x50FA7B),
                warning: Self.color(0xFFB86C),
                error: Self.color(0xFF6161),
                purple: Self.color(0xBD93F9),
                pink: Self.color(0xFF79C6),
                yellow: Self.color(0xF1FA8C)
            )
        case .alucard:
            ThemePalette(
                colorScheme: .light,
                background: Self.color(0xFFFBEB),
                surface: Self.color(0xCFCFDE),
                foreground: Self.color(0x1F1F1F),
                accent: Self.color(0x036A96),
                success: Self.color(0x14710A),
                warning: Self.color(0xA34D14),
                error: Self.color(0xCB3A2A),
                purple: Self.color(0x644AC9),
                pink: Self.color(0xA3144D),
                yellow: Self.color(0x846E15)
            )
        case .tokyoNight:
            // Moon is Tokyo Night's current default and provides stronger compact-UI contrast than Night.
            ThemePalette(
                colorScheme: .dark,
                background: Self.color(0x222436),
                surface: Self.color(0x2F334D),
                foreground: Self.color(0xC8D3F5),
                accent: Self.color(0x82AAFF),
                success: Self.color(0xC3E88D),
                warning: Self.color(0xFF966C),
                error: Self.color(0xFF757F),
                purple: Self.color(0xFCA7EA),
                pink: Self.color(0xC099FF),
                yellow: Self.color(0xFFC777)
            )
        case .tokyoNightDay:
            // Day's darker blue tokens keep text and actions legible on both official background shades.
            ThemePalette(
                colorScheme: .light,
                background: Self.color(0xE1E2E7),
                surface: Self.color(0xD0D5E3),
                foreground: Self.color(0x2E5857),
                accent: Self.color(0x006A83),
                success: Self.color(0x587539),
                warning: Self.color(0x8C6C3E),
                error: Self.color(0xC64343),
                purple: Self.color(0x7847BD),
                pink: Self.color(0xD20065),
                yellow: Self.color(0x8C6C3E)
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
    internal let colorScheme: ColorScheme
    internal let background: Color
    internal let surface: Color
    internal let foreground: Color
    internal let accent: Color
    internal let success: Color
    internal let warning: Color
    internal let error: Color
    internal let purple: Color
    internal let pink: Color
    internal let yellow: Color

    internal var secondaryForeground: Color { foreground.opacity(colorScheme == .light ? 0.95 : 0.72) }
    internal var subtleForeground: Color { foreground.opacity(colorScheme == .light ? 0.92 : 0.66) }
    internal var controlBackground: Color { foreground.opacity(0.16) }
    internal var selectedBackground: Color { accent.opacity(0.22) }
    internal var divider: Color { foreground.opacity(0.24) }
    internal var confettiColors: [Color] { [success, accent, warning, pink, purple, yellow, error] }
}
