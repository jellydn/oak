import SwiftUI

internal struct NotchSessionControlsView: View {
    @ObservedObject var viewModel: FocusSessionViewModel
    let presetSelection: Preset
    let controlSize: CGFloat
    let expandedRingSize: CGFloat
    let onPresetChange: (Preset) -> Void
    let onStart: (Preset) -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onStartNext: () -> Void
    let onReset: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            if viewModel.canStart {
                startView
            } else {
                sessionView
            }
        }
    }

    private var startView: some View {
        HStack(spacing: 6) {
            presetSelector
            Button(
                action: {
                    onStart(presetSelection)
                },
                label: {
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: controlSize, height: controlSize)
                        .background(Color.green.opacity(0.88))
                        .clipShape(Circle())
                }
            )
            .buttonStyle(.plain)
        }
    }

    private var sessionView: some View {
        HStack(spacing: 6) {
            let displayMode = viewModel.presetSettings.countdownDisplayMode
            if displayMode == .circleRing {
                countdownDisplay(
                    mode: displayMode,
                    size: expandedRingSize,
                    fontSize: 14,
                    showSessionType: true
                )
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    countdownDisplay(
                        mode: displayMode,
                        size: expandedRingSize,
                        fontSize: 14
                    )
                    Text(viewModel.currentSessionType)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.52))
                }
            }
            if viewModel.canPause {
                Button(
                    action: {
                        onPause()
                    },
                    label: {
                        Image(systemName: "pause.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 9, weight: .bold))
                            .frame(width: controlSize, height: controlSize)
                            .background(Color.orange.opacity(0.88))
                            .clipShape(Circle())
                    }
                )
                .buttonStyle(.plain)
            } else if viewModel.canResume {
                Button(
                    action: {
                        onResume()
                    },
                    label: {
                        Image(systemName: "play.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 9, weight: .bold))
                            .frame(width: controlSize, height: controlSize)
                            .background(Color.green.opacity(0.88))
                            .clipShape(Circle())
                    }
                )
                .buttonStyle(.plain)
            } else if viewModel.canStartNext {
                Button(
                    action: {
                        onStartNext()
                    },
                    label: {
                        Image(systemName: "forward.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 9, weight: .bold))
                            .frame(width: controlSize, height: controlSize)
                            .background(Color.blue.opacity(0.88))
                            .clipShape(Circle())
                    }
                )
                .buttonStyle(.plain)
            }
            Button(
                action: {
                    onReset()
                },
                label: {
                    Image(systemName: "stop.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 18, height: 18)
                        .background(Color.red.opacity(0.88))
                        .clipShape(Circle())
                }
            )
            .buttonStyle(.plain)
            .help("Stop and reset")
        }
    }

    private var presetSelector: some View {
        HStack(spacing: 2) {
            presetChip(.short)
            presetChip(.long)
        }
        .padding(2)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }

    private func presetChip(_ preset: Preset) -> some View {
        let isSelected = presetSelection == preset
        return Button(
            action: {
                onPresetChange(preset)
            },
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

    private func countdownDisplay(
        mode: CountdownDisplayMode,
        size: CGFloat,
        fontSize: CGFloat,
        showSessionType: Bool = false
    ) -> some View {
        Group {
            if mode == .circleRing {
                ZStack {
                    CircularProgressRing(
                        progress: viewModel.progressPercentage,
                        lineWidth: 2.5,
                        ringColor: viewModel.isPaused ? .orange : .white,
                        backgroundColor: .white.opacity(0.2)
                    )
                    .frame(width: size, height: size)
                    if showSessionType {
                        let sessionType = viewModel.currentSessionType
                        Text(sessionType == "Long Break" ? "Long\nBreak" : sessionType)
                            .font(.system(size: fontSize * 0.5, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                            .minimumScaleFactor(0.65)
                            .multilineTextAlignment(.center)
                            .frame(width: size - 4)
                    }
                }
            } else {
                Text(viewModel.displayTime)
                    .font(.system(size: fontSize, weight: .semibold, design: .monospaced))
                    .foregroundColor(
                        viewModel.isPaused
                            ? Color.orange.opacity(0.95)
                            : Color.white.opacity(0.95)
                    )
            }
        }
    }

    private func presetLabel(for preset: Preset) -> String {
        viewModel.presetSettings.displayName(for: preset)
    }
}
