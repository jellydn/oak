import SwiftUI

/// Persistence and validation helper for session duration presets.
/// Used by PresetSettingsStore to keep the store's file size manageable.
@MainActor
internal struct SessionDurationConfig {
    let shortWork: Int
    let shortBreak: Int
    let shortLongBreak: Int
    let longWork: Int
    let longBreak: Int
    let longLongBreak: Int
    let roundsBeforeLong: Int

    static let minWorkMinutes = 1
    static let maxWorkMinutes = 180
    static let minBreakMinutes = 1
    static let maxBreakMinutes = 90
    static let minRoundsBeforeLongBreak = 2
    static let maxRoundsBeforeLongBreak = 12

    private enum Keys {
        static let shortWorkMinutes = "preset.short.workMinutes"
        static let shortBreakMinutes = "preset.short.breakMinutes"
        static let shortLongBreakMinutes = "preset.short.longBreakMinutes"
        static let longWorkMinutes = "preset.long.workMinutes"
        static let longBreakMinutes = "preset.long.breakMinutes"
        static let longLongBreakMinutes = "preset.long.longBreakMinutes"
        static let roundsBeforeLongBreak = "session.roundsBeforeLongBreak"
    }

    // MARK: - Registration

    static func registerDefaults(in userDefaults: UserDefaults) {
        userDefaults.register(defaults: [
            Keys.shortWorkMinutes: Preset.short.defaultWorkMinutes,
            Keys.shortBreakMinutes: Preset.short.defaultBreakMinutes,
            Keys.shortLongBreakMinutes: Preset.short.defaultLongBreakMinutes,
            Keys.longWorkMinutes: Preset.long.defaultWorkMinutes,
            Keys.longBreakMinutes: Preset.long.defaultBreakMinutes,
            Keys.longLongBreakMinutes: Preset.long.defaultLongBreakMinutes,
            Keys.roundsBeforeLongBreak: 4
        ])
    }

    // MARK: - Read

    static func read(from userDefaults: UserDefaults) -> SessionDurationConfig {
        SessionDurationConfig(
            shortWork: validatedWork(userDefaults.integer(forKey: Keys.shortWorkMinutes)),
            shortBreak: validatedBreak(userDefaults.integer(forKey: Keys.shortBreakMinutes)),
            shortLongBreak: validatedBreak(userDefaults.integer(forKey: Keys.shortLongBreakMinutes)),
            longWork: validatedWork(userDefaults.integer(forKey: Keys.longWorkMinutes)),
            longBreak: validatedBreak(userDefaults.integer(forKey: Keys.longBreakMinutes)),
            longLongBreak: validatedBreak(userDefaults.integer(forKey: Keys.longLongBreakMinutes)),
            roundsBeforeLong: validatedRounds(userDefaults.integer(forKey: Keys.roundsBeforeLongBreak))
        )
    }

    // MARK: - Convenience methods

    func workDuration(for preset: Preset) -> Int {
        workMinutes(for: preset) * 60
    }

    func breakDuration(for preset: Preset) -> Int {
        breakMinutes(for: preset) * 60
    }

    func longBreakDuration(for preset: Preset) -> Int {
        longBreakMinutes(for: preset) * 60
    }

    func displayName(for preset: Preset) -> String {
        "\(workMinutes(for: preset))/\(breakMinutes(for: preset))"
    }

    func workMinutes(for preset: Preset) -> Int {
        switch preset {
        case .short: shortWork
        case .long: longWork
        }
    }

    func breakMinutes(for preset: Preset) -> Int {
        switch preset {
        case .short: shortBreak
        case .long: longBreak
        }
    }

    func longBreakMinutes(for preset: Preset) -> Int {
        switch preset {
        case .short: shortLongBreak
        case .long: longLongBreak
        }
    }

    // MARK: - Save

    static func saveWorkMinutes(_ value: Int, for preset: Preset, to userDefaults: UserDefaults) {
        let validated = validatedWork(value)
        let key = preset == .short ? Keys.shortWorkMinutes : Keys.longWorkMinutes
        userDefaults.set(validated, forKey: key)
    }

    static func saveBreakMinutes(_ value: Int, for preset: Preset, to userDefaults: UserDefaults) {
        let validated = validatedBreak(value)
        let key = preset == .short ? Keys.shortBreakMinutes : Keys.longBreakMinutes
        userDefaults.set(validated, forKey: key)
    }

    static func saveLongBreakMinutes(_ value: Int, for preset: Preset, to userDefaults: UserDefaults) {
        let validated = validatedBreak(value)
        let key = preset == .short ? Keys.shortLongBreakMinutes : Keys.longLongBreakMinutes
        userDefaults.set(validated, forKey: key)
    }

    static func saveRoundsBeforeLongBreak(_ value: Int, to userDefaults: UserDefaults) {
        userDefaults.set(validatedRounds(value), forKey: Keys.roundsBeforeLongBreak)
    }

    // MARK: - Validation

    static func validatedWork(_ value: Int) -> Int {
        max(minWorkMinutes, min(maxWorkMinutes, value))
    }

    static func validatedBreak(_ value: Int) -> Int {
        max(minBreakMinutes, min(maxBreakMinutes, value))
    }

    static func validatedRounds(_ value: Int) -> Int {
        max(minRoundsBeforeLongBreak, min(maxRoundsBeforeLongBreak, value))
    }
}
