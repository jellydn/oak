import AppKit
import CoreGraphics
import SwiftUI

@MainActor
internal final class PresetSettingsStore: ObservableObject {
    // MARK: - Published properties (public API unchanged)

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
    @Published private(set) var playSoundOnBreakCompletion: Bool
    @Published private(set) var countdownDisplayMode: CountdownDisplayMode
    @Published private(set) var alwaysOnTop: Bool
    @Published private(set) var showBelowNotch: Bool
    @Published private(set) var autoStartNextInterval: Bool

    private let userDefaults: UserDefaults

    // MARK: - Static validation constants (delegated)

    static let minWorkMinutes = SessionDurationConfig.minWorkMinutes
    static let maxWorkMinutes = SessionDurationConfig.maxWorkMinutes
    static let minBreakMinutes = SessionDurationConfig.minBreakMinutes
    static let maxBreakMinutes = SessionDurationConfig.maxBreakMinutes
    static let minRoundsBeforeLongBreak = SessionDurationConfig.minRoundsBeforeLongBreak
    static let maxRoundsBeforeLongBreak = SessionDurationConfig.maxRoundsBeforeLongBreak

    // MARK: - Init

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        SessionDurationConfig.registerDefaults(in: userDefaults)
        DisplayConfig.registerDefaults(in: userDefaults)
        BehaviorConfig.registerDefaults(in: userDefaults)

        let duration = SessionDurationConfig.read(from: userDefaults)
        shortWorkMinutes = duration.shortWork
        shortBreakMinutes = duration.shortBreak
        shortLongBreakMinutes = duration.shortLongBreak
        longWorkMinutes = duration.longWork
        longBreakMinutes = duration.longBreak
        longLongBreakMinutes = duration.longLongBreak
        roundsBeforeLongBreak = duration.roundsBeforeLong

        let display = DisplayConfig.read(from: userDefaults)
        displayTarget = display.target
        mainDisplayID = display.mainID
        notchedDisplayID = display.notchedID
        countdownDisplayMode = display.countdownMode
        alwaysOnTop = display.isAlwaysOnTop
        showBelowNotch = display.isBelowNotch

        let behavior = BehaviorConfig.read(from: userDefaults)
        playSoundOnSessionCompletion = behavior.playSoundOnSession
        playSoundOnBreakCompletion = behavior.playSoundOnBreak
        autoStartNextInterval = behavior.autoStartNext

        ensureDisplayIDsInitialized()
    }

    // MARK: - Convenience (delegated to SessionDurationConfig)

    func workDuration(for preset: Preset) -> Int {
        currentDuration().workDuration(for: preset)
    }

    func breakDuration(for preset: Preset) -> Int {
        currentDuration().breakDuration(for: preset)
    }

    func longBreakDuration(for preset: Preset) -> Int {
        currentDuration().longBreakDuration(for: preset)
    }

    func displayName(for preset: Preset) -> String {
        currentDuration().displayName(for: preset)
    }

    func workMinutes(for preset: Preset) -> Int {
        currentDuration().workMinutes(for: preset)
    }

    func breakMinutes(for preset: Preset) -> Int {
        currentDuration().breakMinutes(for: preset)
    }

    func longBreakMinutes(for preset: Preset) -> Int {
        currentDuration().longBreakMinutes(for: preset)
    }

    // MARK: - Set work/break/long-break (delegated)

    func setWorkMinutes(_ minutes: Int, for preset: Preset) {
        let value = SessionDurationConfig.validatedWork(minutes)
        SessionDurationConfig.saveWorkMinutes(value, for: preset, to: userDefaults)
        switch preset {
        case .short: shortWorkMinutes = value
        case .long: longWorkMinutes = value
        }
    }

    func setBreakMinutes(_ minutes: Int, for preset: Preset) {
        let value = SessionDurationConfig.validatedBreak(minutes)
        SessionDurationConfig.saveBreakMinutes(value, for: preset, to: userDefaults)
        switch preset {
        case .short: shortBreakMinutes = value
        case .long: longBreakMinutes = value
        }
    }

    func setLongBreakMinutes(_ minutes: Int, for preset: Preset) {
        let value = SessionDurationConfig.validatedBreak(minutes)
        SessionDurationConfig.saveLongBreakMinutes(value, for: preset, to: userDefaults)
        switch preset {
        case .short: shortLongBreakMinutes = value
        case .long: longLongBreakMinutes = value
        }
    }

    func setRoundsBeforeLongBreak(_ rounds: Int) {
        let value = SessionDurationConfig.validatedRounds(rounds)
        guard roundsBeforeLongBreak != value else { return }
        roundsBeforeLongBreak = value
        SessionDurationConfig.saveRoundsBeforeLongBreak(value, to: userDefaults)
    }

    // MARK: - Display setters (delegated)

    func setCountdownDisplayMode(_ mode: CountdownDisplayMode) {
        guard countdownDisplayMode != mode else { return }
        countdownDisplayMode = mode
        DisplayConfig.saveCountdownMode(mode, to: userDefaults)
    }

    func setAlwaysOnTop(_ value: Bool) {
        guard alwaysOnTop != value else { return }
        alwaysOnTop = value
        DisplayConfig.saveAlwaysOnTop(value, to: userDefaults)
    }

    func setShowBelowNotch(_ value: Bool) {
        guard showBelowNotch != value else { return }
        showBelowNotch = value
        DisplayConfig.saveShowBelowNotch(value, to: userDefaults)
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
                DisplayConfig.saveMainDisplayID(normalizedID, to: userDefaults)
            }
        case .notchedDisplay:
            if let normalizedID, notchedDisplayID != normalizedID {
                notchedDisplayID = normalizedID
                didChangeStoredID = true
                DisplayConfig.saveNotchedDisplayID(normalizedID, to: userDefaults)
            }
        }

        if displayTarget != target {
            displayTarget = target
            DisplayConfig.saveDisplayTarget(target, to: userDefaults)
            return
        }

        if didChangeStoredID {
            displayTarget = target
        }
    }

    func preferredDisplayID(for target: DisplayTarget) -> CGDirectDisplayID? {
        ensureDisplayIDsInitialized()
        return DisplayConfig.preferredDisplayID(
            for: target,
            mainDisplayID: mainDisplayID,
            notchedDisplayID: notchedDisplayID
        )
    }

    // MARK: - Behavior setters (delegated)

    func setPlaySoundOnSessionCompletion(_ value: Bool) {
        guard playSoundOnSessionCompletion != value else { return }
        playSoundOnSessionCompletion = value
        BehaviorConfig.savePlaySoundOnSession(value, to: userDefaults)
    }

    func setPlaySoundOnBreakCompletion(_ value: Bool) {
        guard playSoundOnBreakCompletion != value else { return }
        playSoundOnBreakCompletion = value
        BehaviorConfig.savePlaySoundOnBreak(value, to: userDefaults)
    }

    func setAutoStartNextInterval(_ value: Bool) {
        guard autoStartNextInterval != value else { return }
        autoStartNextInterval = value
        BehaviorConfig.saveAutoStartNext(value, to: userDefaults)
    }

    // MARK: - Reset

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
        setPlaySoundOnBreakCompletion(true)
        setCountdownDisplayMode(.number)
        setAlwaysOnTop(true)
        setShowBelowNotch(false)
        setAutoStartNextInterval(false)
    }

    // MARK: - Private helpers

    private func currentDuration() -> SessionDurationConfig {
        SessionDurationConfig(
            shortWork: shortWorkMinutes,
            shortBreak: shortBreakMinutes,
            shortLongBreak: shortLongBreakMinutes,
            longWork: longWorkMinutes,
            longBreak: longBreakMinutes,
            longLongBreak: longLongBreakMinutes,
            roundsBeforeLong: roundsBeforeLongBreak
        )
    }

    private func ensureDisplayIDsInitialized() {
        DisplayConfig.ensureDisplayIDsInitialized(
            mainDisplayID: &mainDisplayID,
            notchedDisplayID: &notchedDisplayID,
            userDefaults: userDefaults
        )
    }
}
