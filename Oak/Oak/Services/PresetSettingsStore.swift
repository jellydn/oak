import SwiftUI

@MainActor
final class PresetSettingsStore: ObservableObject {
    static let shared = PresetSettingsStore()

    @Published private(set) var shortWorkMinutes: Int
    @Published private(set) var shortBreakMinutes: Int
    @Published private(set) var longWorkMinutes: Int
    @Published private(set) var longBreakMinutes: Int

    private let userDefaults: UserDefaults

    private enum Keys {
        static let shortWorkMinutes = "preset.short.workMinutes"
        static let shortBreakMinutes = "preset.short.breakMinutes"
        static let longWorkMinutes = "preset.long.workMinutes"
        static let longBreakMinutes = "preset.long.breakMinutes"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let defaultShortWork = Preset.short.defaultWorkMinutes
        let defaultShortBreak = Preset.short.defaultBreakMinutes
        let defaultLongWork = Preset.long.defaultWorkMinutes
        let defaultLongBreak = Preset.long.defaultBreakMinutes

        let storedShortWork = userDefaults.integer(forKey: Keys.shortWorkMinutes)
        let storedShortBreak = userDefaults.integer(forKey: Keys.shortBreakMinutes)
        let storedLongWork = userDefaults.integer(forKey: Keys.longWorkMinutes)
        let storedLongBreak = userDefaults.integer(forKey: Keys.longBreakMinutes)

        shortWorkMinutes = Self.validatedWorkMinutes(storedShortWork == 0 ? defaultShortWork : storedShortWork)
        shortBreakMinutes = Self.validatedBreakMinutes(storedShortBreak == 0 ? defaultShortBreak : storedShortBreak)
        longWorkMinutes = Self.validatedWorkMinutes(storedLongWork == 0 ? defaultLongWork : storedLongWork)
        longBreakMinutes = Self.validatedBreakMinutes(storedLongBreak == 0 ? defaultLongBreak : storedLongBreak)
    }

    func workDuration(for preset: Preset) -> Int {
        workMinutes(for: preset) * 60
    }

    func breakDuration(for preset: Preset) -> Int {
        breakMinutes(for: preset) * 60
    }

    func displayName(for preset: Preset) -> String {
        "\(workMinutes(for: preset))/\(breakMinutes(for: preset))"
    }

    func workMinutes(for preset: Preset) -> Int {
        switch preset {
        case .short: return shortWorkMinutes
        case .long: return longWorkMinutes
        }
    }

    func breakMinutes(for preset: Preset) -> Int {
        switch preset {
        case .short: return shortBreakMinutes
        case .long: return longBreakMinutes
        }
    }

    func setWorkMinutes(_ minutes: Int, for preset: Preset) {
        let value = Self.validatedWorkMinutes(minutes)

        switch preset {
        case .short:
            shortWorkMinutes = value
            userDefaults.set(value, forKey: Keys.shortWorkMinutes)
        case .long:
            longWorkMinutes = value
            userDefaults.set(value, forKey: Keys.longWorkMinutes)
        }
    }

    func setBreakMinutes(_ minutes: Int, for preset: Preset) {
        let value = Self.validatedBreakMinutes(minutes)

        switch preset {
        case .short:
            shortBreakMinutes = value
            userDefaults.set(value, forKey: Keys.shortBreakMinutes)
        case .long:
            longBreakMinutes = value
            userDefaults.set(value, forKey: Keys.longBreakMinutes)
        }
    }

    func resetToDefault() {
        setWorkMinutes(Preset.short.defaultWorkMinutes, for: .short)
        setBreakMinutes(Preset.short.defaultBreakMinutes, for: .short)
        setWorkMinutes(Preset.long.defaultWorkMinutes, for: .long)
        setBreakMinutes(Preset.long.defaultBreakMinutes, for: .long)
    }

    private static func validatedWorkMinutes(_ value: Int) -> Int {
        max(1, min(180, value))
    }

    private static func validatedBreakMinutes(_ value: Int) -> Int {
        max(1, min(90, value))
    }
}
