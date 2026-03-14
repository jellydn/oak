import SwiftUI

// MARK: - SettingsMenuView Helpers

internal extension SettingsMenuView {
    func workMinutesBinding(for preset: Preset) -> Binding<Int> {
        Binding(
            get: { presetSettings.workMinutes(for: preset) },
            set: { presetSettings.setWorkMinutes($0, for: preset) }
        )
    }

    func breakMinutesBinding(for preset: Preset) -> Binding<Int> {
        Binding(
            get: { presetSettings.breakMinutes(for: preset) },
            set: { presetSettings.setBreakMinutes($0, for: preset) }
        )
    }

    func longBreakMinutesBinding(for preset: Preset) -> Binding<Int> {
        Binding(
            get: { presetSettings.longBreakMinutes(for: preset) },
            set: { presetSettings.setLongBreakMinutes($0, for: preset) }
        )
    }

    var roundsBeforeLongBreakBinding: Binding<Int> {
        Binding(
            get: { presetSettings.roundsBeforeLongBreak },
            set: { presetSettings.setRoundsBeforeLongBreak($0) }
        )
    }

    var currentVersion: String {
        func getVersion(from bundle: Bundle) -> (String, String)? {
            guard let shortVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String,
                  let buildVersion = bundle.infoDictionary?["CFBundleVersion"] as? String
            else {
                return nil
            }
            return (shortVersion, buildVersion)
        }

        let appBundle = Bundle.main
        let fallbackBundle = Bundle(identifier: "com.productsway.oak.app") ?? Bundle(for: FocusSessionViewModel.self)

        if let (shortVersion, buildVersion) = getVersion(from: appBundle) {
            return "v\(shortVersion) (\(buildVersion))"
        } else if let (shortVersion, buildVersion) = getVersion(from: fallbackBundle) {
            return "v\(shortVersion) (\(buildVersion))"
        }

        return "v0.0.0 (0)"
    }

    var validRangeDescription: String {
        let focusRange = "\(PresetSettingsStore.minWorkMinutes)-\(PresetSettingsStore.maxWorkMinutes)"
        let breakRange = "\(PresetSettingsStore.minBreakMinutes)-\(PresetSettingsStore.maxBreakMinutes)"
        let cycleRange = "\(PresetSettingsStore.minRoundsBeforeLongBreak)"
            + "-\(PresetSettingsStore.maxRoundsBeforeLongBreak)"
        return "Valid range: Focus \(focusRange) min, Break \(breakRange) min, Long cycle \(cycleRange) sessions"
    }
}
