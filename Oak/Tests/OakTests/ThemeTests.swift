import AppKit
import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class ThemeTests: XCTestCase {
    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var presetSettings: PresetSettingsStore!

    override func setUp() async throws {
        suiteName = "OakTests.ThemeTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw NSError(domain: "ThemeTests", code: 1)
        }
        defaults.removePersistentDomain(forName: suiteName)
        userDefaults = defaults
        presetSettings = PresetSettingsStore(userDefaults: defaults)
    }

    override func tearDown() async throws {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        presetSettings = nil
        userDefaults = nil
    }

    func testThemeChoicesHaveStableNames() {
        XCTAssertEqual(
            AppTheme.allCases.map(\.displayName),
            [
                "Oak",
                "Kanagawa",
                "Kanagawa Lotus",
                "Dracula",
                "Alucard (Dracula Light)",
                "Tokyo Night",
                "Tokyo Night Day"
            ]
        )
    }

    func testThemeDefaultsToOak() {
        XCTAssertEqual(presetSettings.theme, .oak)
    }

    internal func testNamedThemesUseDocumentedCoreColors() throws {
        try assertColor(.kanagawa, background: 0x1F1F28, foreground: 0xDCD7BA, accent: 0x7E9CD8)
        try assertColor(.kanagawaLotus, background: 0xF2ECBC, foreground: 0x43436C, accent: 0x4D699B)
        try assertColor(.dracula, background: 0x282A36, foreground: 0xF8F8F2, accent: 0x8BE9FD)
        try assertColor(.alucard, background: 0xFFFBEB, foreground: 0x1F1F1F, accent: 0x036A96)
        try assertColor(.tokyoNight, background: 0x222436, foreground: 0xC8D3F5, accent: 0x82AAFF)
        try assertColor(.tokyoNightDay, background: 0xE1E2E7, foreground: 0x2E5857, accent: 0x006A83)
    }

    internal func testEachSelectedThemePersists() {
        for theme in AppTheme.allCases {
            presetSettings.setTheme(theme)

            let reloadedSettings = PresetSettingsStore(userDefaults: userDefaults)

            XCTAssertEqual(reloadedSettings.theme, theme)
        }
    }

    internal func testThemeColorSchemesMatchTheirVariants() {
        XCTAssertEqual(
            AppTheme.allCases.filter { $0.palette.colorScheme == .light },
            [.kanagawaLotus, .alucard, .tokyoNightDay]
        )
    }

    func testUnknownPersistedThemeFallsBackToOak() {
        userDefaults.set("removed-theme", forKey: "appearance.theme")

        let reloadedSettings = PresetSettingsStore(userDefaults: userDefaults)

        XCTAssertEqual(reloadedSettings.theme, .oak)
    }

    func testResetRestoresOakTheme() {
        presetSettings.setTheme(.dracula)

        presetSettings.resetToDefault()

        XCTAssertEqual(presetSettings.theme, .oak)
    }

    func testThemeTextMeetsWCAGAAContrast() throws {
        for theme in AppTheme.allCases {
            let palette = theme.palette
            for background in [palette.background, palette.surface] {
                for color in [palette.foreground, palette.secondaryForeground, palette.subtleForeground] {
                    XCTAssertGreaterThanOrEqual(
                        try contrastRatio(color, over: background),
                        4.5,
                        "\(theme.displayName) text must meet WCAG AA on each app background"
                    )
                }
            }
        }
    }

    func testThemeActionColorsMeetNonTextContrast() throws {
        for theme in AppTheme.allCases {
            let palette = theme.palette
            for background in [palette.background, palette.surface] {
                for color in [palette.accent, palette.success, palette.warning, palette.error] {
                    XCTAssertGreaterThanOrEqual(
                        try contrastRatio(color, over: background),
                        3,
                        "\(theme.displayName) action colors must remain visible on each app background"
                    )
                }
            }
        }
    }

    private func contrastRatio(_ foreground: Color, over background: Color) throws -> Double {
        let foregroundComponents = try colorComponents(foreground)
        let backgroundComponents = try colorComponents(background)
        let compositedForeground = RGBComponents(
            red: foregroundComponents.red * foregroundComponents.alpha
                + backgroundComponents.red * (1 - foregroundComponents.alpha),
            green: foregroundComponents.green * foregroundComponents.alpha
                + backgroundComponents.green * (1 - foregroundComponents.alpha),
            blue: foregroundComponents.blue * foregroundComponents.alpha
                + backgroundComponents.blue * (1 - foregroundComponents.alpha),
            alpha: 1
        )
        let lighter = max(relativeLuminance(compositedForeground), relativeLuminance(backgroundComponents))
        let darker = min(relativeLuminance(compositedForeground), relativeLuminance(backgroundComponents))
        return (lighter + 0.05) / (darker + 0.05)
    }

    private func assertColor(
        _ theme: AppTheme,
        background: UInt32,
        foreground: UInt32,
        accent: UInt32
    ) throws {
        try assertColor(theme.palette.background, equals: background)
        try assertColor(theme.palette.foreground, equals: foreground)
        try assertColor(theme.palette.accent, equals: accent)
    }

    private func assertColor(_ color: Color, equals hex: UInt32) throws {
        let components = try colorComponents(color)
        XCTAssertEqual(components.red, Double((hex >> 16) & 0xFF) / 255, accuracy: 0.001)
        XCTAssertEqual(components.green, Double((hex >> 8) & 0xFF) / 255, accuracy: 0.001)
        XCTAssertEqual(components.blue, Double(hex & 0xFF) / 255, accuracy: 0.001)
    }

    private func colorComponents(_ color: Color) throws -> RGBComponents {
        guard let convertedColor = NSColor(color).usingColorSpace(.sRGB) else {
            throw NSError(domain: "ThemeTests", code: 2)
        }
        return RGBComponents(
            red: Double(convertedColor.redComponent),
            green: Double(convertedColor.greenComponent),
            blue: Double(convertedColor.blueComponent),
            alpha: Double(convertedColor.alphaComponent)
        )
    }

    private func relativeLuminance(_ components: RGBComponents) -> Double {
        0.2126 * linearized(components.red)
            + 0.7152 * linearized(components.green)
            + 0.0722 * linearized(components.blue)
    }

    private func linearized(_ component: Double) -> Double {
        component <= 0.04045
            ? component / 12.92
            : pow((component + 0.055) / 1.055, 2.4)
    }
}

private struct RGBComponents {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
}
