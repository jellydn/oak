import AppKit
import CoreGraphics
import SwiftUI

/// Persistence and validation helper for display/window settings.
/// Used by PresetSettingsStore to keep the store's file size manageable.
@MainActor
internal struct DisplayConfig {
    let target: DisplayTarget
    let mainID: UInt32?
    let notchedID: UInt32?
    let countdownMode: CountdownDisplayMode
    let isAlwaysOnTop: Bool
    let isBelowNotch: Bool

    private enum Keys {
        static let displayTarget = "display.target"
        static let mainDisplayID = "display.main.id"
        static let notchedDisplayID = "display.notched.id"
        static let countdownDisplayMode = "countdown.displayMode"
        static let alwaysOnTop = "window.alwaysOnTop"
        static let showBelowNotch = "window.showBelowNotch"
    }

    static func registerDefaults(in userDefaults: UserDefaults) {
        userDefaults.register(defaults: [
            Keys.displayTarget: DisplayTarget.mainDisplay.rawValue,
            Keys.countdownDisplayMode: CountdownDisplayMode.number.rawValue,
            Keys.alwaysOnTop: true,
            Keys.showBelowNotch: false
        ])
    }

    static func read(from userDefaults: UserDefaults) -> DisplayConfig {
        let rawTarget = userDefaults.string(forKey: Keys.displayTarget) ?? DisplayTarget.mainDisplay.rawValue
        let rawMode = userDefaults.string(forKey: Keys.countdownDisplayMode) ?? CountdownDisplayMode.number.rawValue
        return DisplayConfig(
            target: DisplayTarget(rawValue: rawTarget) ?? .mainDisplay,
            mainID: (userDefaults.object(forKey: Keys.mainDisplayID) as? NSNumber)?.uint32Value,
            notchedID: (userDefaults.object(forKey: Keys.notchedDisplayID) as? NSNumber)?.uint32Value,
            countdownMode: CountdownDisplayMode(rawValue: rawMode) ?? .number,
            isAlwaysOnTop: userDefaults.bool(forKey: Keys.alwaysOnTop),
            isBelowNotch: userDefaults.bool(forKey: Keys.showBelowNotch)
        )
    }

    static func saveCountdownMode(_ mode: CountdownDisplayMode, to userDefaults: UserDefaults) {
        userDefaults.set(mode.rawValue, forKey: Keys.countdownDisplayMode)
    }

    static func saveAlwaysOnTop(_ value: Bool, to userDefaults: UserDefaults) {
        userDefaults.set(value, forKey: Keys.alwaysOnTop)
    }

    static func saveShowBelowNotch(_ value: Bool, to userDefaults: UserDefaults) {
        userDefaults.set(value, forKey: Keys.showBelowNotch)
    }

    static func saveDisplayTarget(_ target: DisplayTarget, to userDefaults: UserDefaults) {
        userDefaults.set(target.rawValue, forKey: Keys.displayTarget)
    }

    static func saveMainDisplayID(_ id: UInt32, to userDefaults: UserDefaults) {
        userDefaults.set(id, forKey: Keys.mainDisplayID)
    }

    static func saveNotchedDisplayID(_ id: UInt32, to userDefaults: UserDefaults) {
        userDefaults.set(id, forKey: Keys.notchedDisplayID)
    }

    static func ensureDisplayIDsInitialized(
        mainDisplayID: inout UInt32?,
        notchedDisplayID: inout UInt32?,
        userDefaults: UserDefaults
    ) {
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

    static func preferredDisplayID(
        for target: DisplayTarget,
        mainDisplayID: UInt32?,
        notchedDisplayID: UInt32?
    ) -> CGDirectDisplayID? {
        switch target {
        case .mainDisplay:
            mainDisplayID.map { CGDirectDisplayID($0) }
        case .notchedDisplay:
            notchedDisplayID.map { CGDirectDisplayID($0) }
        }
    }
}
