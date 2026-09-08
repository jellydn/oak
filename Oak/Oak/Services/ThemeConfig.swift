import Foundation

internal enum ThemeConfig {
    private static let themeKey = "appearance.theme"

    static func registerDefaults(in userDefaults: UserDefaults) {
        userDefaults.register(defaults: [themeKey: AppTheme.oak.rawValue])
    }

    static func read(from userDefaults: UserDefaults) -> AppTheme {
        guard let rawValue = userDefaults.string(forKey: themeKey),
              let theme = AppTheme(rawValue: rawValue)
        else {
            return .oak
        }
        return theme
    }

    static func save(_ theme: AppTheme, to userDefaults: UserDefaults) {
        userDefaults.set(theme.rawValue, forKey: themeKey)
    }
}
