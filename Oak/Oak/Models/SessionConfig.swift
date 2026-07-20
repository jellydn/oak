import Foundation

/// Configuration snapshot consumed by `SessionEngine`.
///
/// The shell builds this from `PresetSettingsStore` for the currently
/// selected `Preset` and pushes updates via `SessionEngine.updateConfig(_:)`
/// whenever preferences change.
internal struct SessionConfig: Equatable {
    let workSeconds: Int
    let breakSeconds: Int
    let longBreakSeconds: Int
    let roundsBeforeLongBreak: Int
    let playSoundOnSessionCompletion: Bool
    let playSoundOnBreakCompletion: Bool
    let autoStartNextInterval: Bool
}
