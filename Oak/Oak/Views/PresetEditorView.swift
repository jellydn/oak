import SwiftUI

internal struct PresetEditorView: View {
    @ObservedObject internal var presetSettings: PresetSettingsStore
    internal let title: String
    internal let preset: Preset

    private var palette: ThemePalette {
        presetSettings.theme.palette
    }

    internal var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(title) preset")
                .font(.subheadline.weight(.semibold))

            Divider()

            durationRow(
                "Focus",
                minutes: presetSettings.workMinutes(for: preset),
                binding: workMinutesBinding,
                range: PresetSettingsStore.minWorkMinutes ... PresetSettingsStore.maxWorkMinutes
            )
            durationRow(
                "Short break",
                minutes: presetSettings.breakMinutes(for: preset),
                binding: breakMinutesBinding,
                range: PresetSettingsStore.minBreakMinutes ... PresetSettingsStore.maxBreakMinutes
            )
            durationRow(
                "Long break",
                minutes: presetSettings.longBreakMinutes(for: preset),
                binding: longBreakMinutesBinding,
                range: PresetSettingsStore.minBreakMinutes ... PresetSettingsStore.maxBreakMinutes
            )
        }
        .padding(12)
        .background(palette.controlBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func durationRow(
        _ label: String,
        minutes: Int,
        binding: Binding<Int>,
        range: ClosedRange<Int>
    ) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.caption)
                .foregroundColor(palette.secondaryForeground)

            Spacer(minLength: 8)

            Stepper(value: binding, in: range) {
                Text("\(minutes) min")
                    .font(.caption.monospacedDigit())
                    .frame(minWidth: 48, alignment: .trailing)
            }
            .fixedSize()
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
