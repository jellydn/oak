import AppKit
import CoreGraphics
import SwiftUI

@MainActor
internal final class PresetSettingsStore: ObservableObject {
    static let shared = PresetSettingsStore()

    static let minWorkMinutes = 1
    static let maxWorkMinutes = 180
    static let minBreakMinutes = 1
    static let maxBreakMinutes = 90
    static let minRoundsBeforeLongBreak = 2
    static let maxRoundsBeforeLongBreak = 12

    @Published private(set) var shortWorkMinutes: Int
    @Published private(set) var shortBreakMinutes: Int
    @Published private(set) var shortLongBreakMinutes: Int
    @Published private(set) var longWorkMinutes: Int
    @Published private(set) var longBreakMinutes: Int
    @Published private(set) var longLongBreakMinutes: Int
    @Published private(set) var roundsBeforeLongBreak: Int
    @Published private(set) var displayTarget: DisplayTarget
    @Published private(set) var mainDisplayID: UInt32?
    @Published private(set) var notchedDisplayID: UInt32?
    @Published private(set) var playSoundOnSessionCompletion: Bool
    @Published private(set) var countdownDisplayMode: CountdownDisplayMode
    @Published private(set) var alwaysOnTop: Bool
    @Published private(set) var showBelowNotch: Bool

    private let userDefaults: UserDefaults

    private enum Keys {
        static let shortWorkMinutes = "preset.short.workMinutes"
        static let shortBreakMinutes = "preset.short.breakMinutes"
        static let shortLongBreakMinutes = "preset.short.longBreakMinutes"
        static let longWorkMinutes = "preset.long.workMinutes"
        static let longBreakMinutes = "preset.long.breakMinutes"
        static let longLongBreakMinutes = "preset.long.longBreakMinutes"
        static let roundsBeforeLongBreak = "session.roundsBeforeLongBreak"
        static let displayTarget = "display.target"
        static let mainDisplayID = "display.main.id"
        static let notchedDisplayID = "display.notched.id"
        static let playSoundOnSessionCompletion = "session.completion.playSound"
        static let countdownDisplayMode = "countdown.displayMode"
        static let alwaysOnTop = "window.alwaysOnTop"
        static let showBelowNotch = "window.showBelowNotch"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let defaults: [String: Any] = [
            Keys.shortWorkMinutes: Preset.short.defaultWorkMinutes,
            Keys.shortBreakMinutes: Preset.short.defaultBreakMinutes,
            Keys.shortLongBreakMinutes: Preset.short.defaultLongBreakMinutes,
            Keys.longWorkMinutes: Preset.long.defaultWorkMinutes,
            Keys.longBreakMinutes: Preset.long.defaultBreakMinutes,
            Keys.longLongBreakMinutes: Preset.long.defaultLongBreakMinutes,
            Keys.roundsBeforeLongBreak: 4,
            Keys.displayTarget: DisplayTarget.mainDisplay.rawValue,
            Keys.playSoundOnSessionCompletion: true,
            Keys.countdownDisplayMode: CountdownDisplayMode.number.rawValue,
            Keys.alwaysOnTop: false,
            Keys.showBelowNotch: false
        ]
        userDefaults.register(defaults: defaults)

        shortWorkMinutes = Self.validatedWorkMinutes(userDefaults.integer(forKey: Keys.shortWorkMinutes))
        shortBreakMinutes = Self.validatedBreakMinutes(userDefaults.integer(forKey: Keys.shortBreakMinutes))
        shortLongBreakMinutes = Self.validatedBreakMinutes(userDefaults.integer(forKey: Keys.shortLongBreakMinutes))
        longWorkMinutes = Self.validatedWorkMinutes(userDefaults.integer(forKey: Keys.longWorkMinutes))
        longBreakMinutes = Self.validatedBreakMinutes(userDefaults.integer(forKey: Keys.longBreakMinutes))
        longLongBreakMinutes = Self.validatedBreakMinutes(userDefaults.integer(forKey: Keys.longLongBreakMinutes))
        roundsBeforeLongBreak = Self.validatedRoundsBeforeLongBreak(
            userDefaults.integer(forKey: Keys.roundsBeforeLongBreak)
        )
        let rawDisplayTarget = userDefaults.string(forKey: Keys.displayTarget) ?? DisplayTarget.mainDisplay.rawValue
        displayTarget = DisplayTarget(rawValue: rawDisplayTarget) ?? .mainDisplay
        mainDisplayID = (userDefaults.object(forKey: Keys.mainDisplayID) as? NSNumber)?.uint32Value
        notchedDisplayID = (userDefaults.object(forKey: Keys.notchedDisplayID) as? NSNumber)?.uint32Value
        playSoundOnSessionCompletion = userDefaults.bool(forKey: Keys.playSoundOnSessionCompletion)
        let rawCountdownMode = userDefaults.string(forKey: Keys.countdownDisplayMode)
            ?? CountdownDisplayMode.number.rawValue
        countdownDisplayMode = CountdownDisplayMode(rawValue: rawCountdownMode) ?? .number
        alwaysOnTop = userDefaults.bool(forKey: Keys.alwaysOnTop)
        showBelowNotch = userDefaults.bool(forKey: Keys.showBelowNotch)
        ensureDisplayIDsInitialized()
    }

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

    func longBreakMinutes(for preset: Preset) -> Int {
        switch preset {
        case .short: return shortLongBreakMinutes
        case .long: return longLongBreakMinutes
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

    func setLongBreakMinutes(_ minutes: Int, for preset: Preset) {
        let value = Self.validatedBreakMinutes(minutes)

        switch preset {
        case .short:
            shortLongBreakMinutes = value
            userDefaults.set(value, forKey: Keys.shortLongBreakMinutes)
        case .long:
            longLongBreakMinutes = value
            userDefaults.set(value, forKey: Keys.longLongBreakMinutes)
        }
    }

    func setRoundsBeforeLongBreak(_ rounds: Int) {
        let value = Self.validatedRoundsBeforeLongBreak(rounds)
        guard roundsBeforeLongBreak != value else { return }
        roundsBeforeLongBreak = value
        userDefaults.set(value, forKey: Keys.roundsBeforeLongBreak)
    }

    func resetToDefault() {
        setWorkMinutes(Preset.short.defaultWorkMinutes, for: .short)
        setBreakMinutes(Preset.short.defaultBreakMinutes, for: .short)
        setLongBreakMinutes(Preset.short.defaultLongBreakMinutes, for: .short)
        setWorkMinutes(Preset.long.defaultWorkMinutes, for: .long)
        setBreakMinutes(Preset.long.defaultBreakMinutes, for: .long)
        setLongBreakMinutes(Preset.long.defaultLongBreakMinutes, for: .long)
        setRoundsBeforeLongBreak(4)
        setDisplayTarget(.mainDisplay, screenID: nil)
        setPlaySoundOnSessionCompletion(true)
        setCountdownDisplayMode(.number)
        setAlwaysOnTop(false)
    }

    func setPlaySoundOnSessionCompletion(_ value: Bool) {
        guard playSoundOnSessionCompletion != value else { return }
        playSoundOnSessionCompletion = value
        userDefaults.set(value, forKey: Keys.playSoundOnSessionCompletion)
    }

    func setCountdownDisplayMode(_ mode: CountdownDisplayMode) {
        guard countdownDisplayMode != mode else { return }
        countdownDisplayMode = mode
        userDefaults.set(mode.rawValue, forKey: Keys.countdownDisplayMode)
    }

    func setAlwaysOnTop(_ value: Bool) {
        guard alwaysOnTop != value else { return }
        alwaysOnTop = value
        userDefaults.set(value, forKey: Keys.alwaysOnTop)
    }

    func setShowBelowNotch(_ value: Bool) {
        guard showBelowNotch != value else { return }
        showBelowNotch = value
        userDefaults.set(value, forKey: Keys.showBelowNotch)
    }

    func setDisplayTarget(_ target: DisplayTarget) {
        setDisplayTarget(target, screenID: nil)
    }

    func setDisplayTarget(_ target: DisplayTarget, screenID: CGDirectDisplayID?) {
        ensureDisplayIDsInitialized()
        let normalizedID = screenID.map { UInt32($0) }
        var didChangeStoredID = false

        switch target {
        case .mainDisplay:
            if let normalizedID, mainDisplayID != normalizedID {
                mainDisplayID = normalizedID
                didChangeStoredID = true
                userDefaults.set(normalizedID, forKey: Keys.mainDisplayID)
            }
        case .notchedDisplay:
            if let normalizedID, notchedDisplayID != normalizedID {
                notchedDisplayID = normalizedID
                didChangeStoredID = true
                userDefaults.set(normalizedID, forKey: Keys.notchedDisplayID)
            }
        }

        if displayTarget != target {
            displayTarget = target
            userDefaults.set(target.rawValue, forKey: Keys.displayTarget)
            return
        }

        if didChangeStoredID {
            // Re-emit to notify subscribers that target screen mapping changed.
            displayTarget = target
        }
    }

    func preferredDisplayID(for target: DisplayTarget) -> CGDirectDisplayID? {
        ensureDisplayIDsInitialized()
        switch target {
        case .mainDisplay:
            return mainDisplayID.map { CGDirectDisplayID($0) }
        case .notchedDisplay:
            return notchedDisplayID.map { CGDirectDisplayID($0) }
        }
    }

    private func ensureDisplayIDsInitialized() {
        let allDisplayIDs = NSScreen.screens.compactMap { NSScreen.displayID(for: $0) }
        guard !allDisplayIDs.isEmpty else { return }

        let primaryID = CGMainDisplayID()
        let resolvedPrimaryID = allDisplayIDs.first { $0 == primaryID } ?? allDisplayIDs[0]

        if mainDisplayID == nil {
            let value = UInt32(resolvedPrimaryID)
            mainDisplayID = value
            userDefaults.set(value, forKey: Keys.mainDisplayID)
        }

        if notchedDisplayID == nil {
            let secondaryID = allDisplayIDs.first { $0 != resolvedPrimaryID } ?? resolvedPrimaryID
            let value = UInt32(secondaryID)
            notchedDisplayID = value
            userDefaults.set(value, forKey: Keys.notchedDisplayID)
        }
    }

    private static func validatedWorkMinutes(_ value: Int) -> Int {
        max(minWorkMinutes, min(maxWorkMinutes, value))
    }

    private static func validatedBreakMinutes(_ value: Int) -> Int {
        max(minBreakMinutes, min(maxBreakMinutes, value))
    }

    private static func validatedRoundsBeforeLongBreak(_ value: Int) -> Int {
        max(minRoundsBeforeLongBreak, min(maxRoundsBeforeLongBreak, value))
    }
}
