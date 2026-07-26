import SwiftUI

/// Extracted from SettingsMenuView — renders stepper controls for focus, break, and long-break
/// minutes within a single preset.
internal struct PresetEditorView: View {
    @ObservedObject var presetSettings: PresetSettingsStore
    let title: String
    let preset: Preset

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium))

            HStack(spacing: 8) {
                Text("Focus")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .leading)

                Stepper(
                    value: workMinutesBinding,
                    in: PresetSettingsStore.minWorkMinutes ... PresetSettingsStore.maxWorkMinutes
                ) {
                    Text("\(presetSettings.workMinutes(for: preset)) min")
                        .font(.caption)
                }
            }

            HStack(spacing: 8) {
                Text("Break")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .leading)

                Stepper(
                    value: breakMinutesBinding,
                    in: PresetSettingsStore.minBreakMinutes ... PresetSettingsStore.maxBreakMinutes
                ) {
                    Text("\(presetSettings.breakMinutes(for: preset)) min")
                        .font(.caption)
                }
            }

            HStack(spacing: 8) {
                Text("Long")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .leading)

                Stepper(
                    value: longBreakMinutesBinding,
                    in: PresetSettingsStore.minBreakMinutes ... PresetSettingsStore.maxBreakMinutes
                ) {
                    Text("\(presetSettings.longBreakMinutes(for: preset)) min")
                        .font(.caption)
                }
            }
        }
    }

    private var workMinutesBinding: Binding<Int> {
        Binding(
            get: { presetSettings.workMinutes(for: preset) },
            set: { presetSettings.setWorkMinutes($0, for: preset) }
        )
    }

    private var breakMinutesBinding: Binding<Int> {
        Binding(
            get: { presetSettings.breakMinutes(for: preset) },
            set: { presetSettings.setBreakMinutes($0, for: preset) }
        )
    }

    private var longBreakMinutesBinding: Binding<Int> {
        Binding(
            get: { presetSettings.longBreakMinutes(for: preset) },
            set: { presetSettings.setLongBreakMinutes($0, for: preset) }
        )
    }
}
