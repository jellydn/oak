import SwiftUI

/// Persistence helper for session behavior flags (sound, auto-start).
/// Used by PresetSettingsStore to keep the store's file size manageable.
@MainActor
internal struct BehaviorConfig {
    let playSoundOnSession: Bool
    let playSoundOnBreak: Bool
    let autoStartNext: Bool

    private enum Keys {
        static let playSoundOnSessionCompletion = "session.completion.playSound"
        static let playSoundOnBreakCompletion = "session.completion.playSound.break"
        static let autoStartNextInterval = "session.autoStartNextInterval"
    }

    static func registerDefaults(in userDefaults: UserDefaults) {
        userDefaults.register(defaults: [
            Keys.playSoundOnSessionCompletion: true,
            Keys.playSoundOnBreakCompletion: true,
            Keys.autoStartNextInterval: false
        ])
    }

    static func read(from userDefaults: UserDefaults) -> BehaviorConfig {
        BehaviorConfig(
            playSoundOnSession: userDefaults.bool(forKey: Keys.playSoundOnSessionCompletion),
            playSoundOnBreak: userDefaults.bool(forKey: Keys.playSoundOnBreakCompletion),
            autoStartNext: userDefaults.bool(forKey: Keys.autoStartNextInterval)
        )
    }

    static func savePlaySoundOnSession(_ value: Bool, to userDefaults: UserDefaults) {
        userDefaults.set(value, forKey: Keys.playSoundOnSessionCompletion)
    }

    static func savePlaySoundOnBreak(_ value: Bool, to userDefaults: UserDefaults) {
        userDefaults.set(value, forKey: Keys.playSoundOnBreakCompletion)
    }

    static func saveAutoStartNext(_ value: Bool, to userDefaults: UserDefaults) {
        userDefaults.set(value, forKey: Keys.autoStartNextInterval)
    }
}
