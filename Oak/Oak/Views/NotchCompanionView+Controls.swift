import SwiftUI

/// Control buttons for the notch companion view (audio, progress, settings, expand, preset selector)
extension NotchCompanionView {
    var audioButton: some View {
        Button(
            action: { showAudioMenu.toggle() },
            label: {
                ZStack {
                    Circle()
                        .fill(
                            viewModel.audioManager.isPlaying
                                ? Color.blue.opacity(isExpanded ? 0.25 : 0.34)
                                : Color.white.opacity(visualStyle.neutralControlOpacity)
                        )
                        .frame(width: controlSize, height: controlSize)

                    Image(systemName: viewModel.audioManager.selectedTrack.systemImageName)
                        .foregroundColor(viewModel.audioManager.isPlaying ? .blue : .white.opacity(0.7))
                        .font(.system(size: 9))
                }
            }
        )
        .buttonStyle(.plain)
    }

    var progressButton: some View {
        Button(
            action: { showProgressMenu.toggle() },
            label: {
                ZStack {
                    Circle()
                        .fill(
                            viewModel.streakDays > 0
                                ? Color.orange.opacity(isExpanded ? 0.24 : 0.34)
                                : Color.white.opacity(visualStyle.neutralControlOpacity)
                        )
                        .frame(width: controlSize, height: controlSize)

                    if viewModel.streakDays > 0 {
                        Text("\(viewModel.streakDays)")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.orange)
                    } else {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 9))
                    }
                }
            }
        )
        .buttonStyle(.plain)
    }

    var settingsButton: some View {
        Button(
            action: { showSettingsMenu.toggle() },
            label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(visualStyle.neutralControlOpacity))
                        .frame(width: controlSize, height: controlSize)

                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 9))
                }
            }
        )
        .buttonStyle(.plain)
        .help("Settings")
    }

    var expandToggleButton: some View {
        Button(
            action: {
                let shouldExpand = !isExpandedByToggle
                isExpandedByToggle = shouldExpand
                if !shouldExpand {
                    showAudioMenu = false
                    showProgressMenu = false
                    showSettingsMenu = false
                }
            },
            label: {
                Image(systemName: isExpanded ? "chevron.compact.left" : "chevron.compact.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
                    .frame(width: controlSize, height: controlSize)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(visualStyle.toggleControlOpacity))
                    )
            }
        )
        .buttonStyle(.plain)
        .contentShape(Circle())
        .help(isExpanded ? "Collapse" : "Expand")
    }

    var presetSelector: some View {
        HStack(spacing: 2) {
            presetChip(.short)
            presetChip(.long)
        }
        .padding(2)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(visualStyle.presetCapsuleOpacity))
        )
    }

    func presetChip(_ preset: Preset) -> some View {
        let isSelected = presetSelection == preset
        return Button(
            action: { presetSelection = preset },
            label: {
                Text(presetLabel(for: preset))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.62))
                    .frame(minWidth: 54, minHeight: 18)
                    .background(
                        Capsule(style: .continuous)
                            .fill(isSelected ? Color.white.opacity(0.16) : Color.clear)
                    )
            }
        )
        .buttonStyle(.plain)
    }

    func presetLabel(for preset: Preset) -> String {
        viewModel.presetSettings.displayName(for: preset)
    }

    func notifyExpansionChanged(_ expanded: Bool) {
        guard lastReportedExpansion != expanded else { return }
        lastReportedExpansion = expanded
        DispatchQueue.main.async {
            onExpansionChanged(expanded)
        }
    }
}
