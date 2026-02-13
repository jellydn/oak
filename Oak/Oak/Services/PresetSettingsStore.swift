import SwiftUI

@MainActor
internal final class PresetSettingsStore: ObservableObject {
    static let shared = PresetSettingsStore()

    static let minWorkMinutes = 1
    static let maxWorkMinutes = 180
    static let minBreakMinutes = 1
    static let maxBreakMinutes = 90

    @Published private(set) var shortWorkMinutes: Int
    @Published private(set) var shortBreakMinutes: Int
    @Published private(set) var longWorkMinutes: Int
    @Published private(set) var longBreakMinutes: Int
    @Published private(set) var displayTarget: DisplayTarget

    private let userDefaults: UserDefaults

    private enum Keys {
        static let shortWorkMinutes = "preset.short.workMinutes"
        static let shortBreakMinutes = "preset.short.breakMinutes"
        static let longWorkMinutes = "preset.long.workMinutes"
        static let longBreakMinutes = "preset.long.breakMinutes"
        static let displayTarget = "display.target"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let defaults: [String: Any] = [
            Keys.shortWorkMinutes: Preset.short.defaultWorkMinutes,
            Keys.shortBreakMinutes: Preset.short.defaultBreakMinutes,
            Keys.longWorkMinutes: Preset.long.defaultWorkMinutes,
            Keys.longBreakMinutes: Preset.long.defaultBreakMinutes,
            Keys.displayTarget: DisplayTarget.mainDisplay.rawValue
        ]
        userDefaults.register(defaults: defaults)

        shortWorkMinutes = Self.validatedWorkMinutes(userDefaults.integer(forKey: Keys.shortWorkMinutes))
        shortBreakMinutes = Self.validatedBreakMinutes(userDefaults.integer(forKey: Keys.shortBreakMinutes))
        longWorkMinutes = Self.validatedWorkMinutes(userDefaults.integer(forKey: Keys.longWorkMinutes))
        longBreakMinutes = Self.validatedBreakMinutes(userDefaults.integer(forKey: Keys.longBreakMinutes))
        let rawDisplayTarget = userDefaults.string(forKey: Keys.displayTarget) ?? DisplayTarget.mainDisplay.rawValue
        displayTarget = DisplayTarget(rawValue: rawDisplayTarget) ?? .mainDisplay
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
        setDisplayTarget(.mainDisplay)
    }

    func setDisplayTarget(_ target: DisplayTarget) {
        guard displayTarget != target else { return }
        displayTarget = target
        userDefaults.set(target.rawValue, forKey: Keys.displayTarget)
    }

    private static func validatedWorkMinutes(_ value: Int) -> Int {
        max(minWorkMinutes, min(maxWorkMinutes, value))
    }

    private static func validatedBreakMinutes(_ value: Int) -> Int {
        max(minBreakMinutes, min(maxBreakMinutes, value))
    }
}
