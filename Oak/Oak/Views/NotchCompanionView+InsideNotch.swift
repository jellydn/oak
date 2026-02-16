import SwiftUI

internal extension NotchCompanionView {
    var insideNotchCompactContent: some View {
        HStack(spacing: 0) {
            compactLeadingDisplay

            Spacer(minLength: 24)

            HStack(spacing: 6) {
                compactPrimaryActionButton
                expandToggleButton
            }
        }
    }

    var insideNotchExpandedContent: some View {
        HStack(spacing: 6) {
            insideNotchExpandedLeading
            insideNotchExpandedPrimaryControls

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                audioButton
                progressButton
                settingsButton
                expandToggleButton
            }
        }
    }

    @ViewBuilder
    private var insideNotchExpandedLeading: some View {
        if viewModel.canStart {
            Text(viewModel.presetSettings.displayName(for: viewModel.selectedPreset))
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.68))
        } else {
            let displayMode = viewModel.presetSettings.countdownDisplayMode
            if displayMode == .circleRing {
                countdownDisplay(
                    mode: displayMode,
                    size: expandedRingSize,
                    fontSize: 14,
                    showSessionType: true
                )
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    countdownDisplay(mode: displayMode, size: expandedRingSize, fontSize: 13)
                    Text(viewModel.currentSessionType)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.56))
                }
            }
        }
    }

    @ViewBuilder
    private var insideNotchExpandedPrimaryControls: some View {
        if viewModel.canStart {
            Button(
                action: { viewModel.startSession() },
                label: {
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 18, height: 18)
                        .background(Color.green.opacity(0.88))
                        .clipShape(Circle())
                }
            )
            .buttonStyle(.plain)
        } else {
            if viewModel.canPause {
                Button(
                    action: { viewModel.pauseSession() },
                    label: {
                        Image(systemName: "pause.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 9, weight: .bold))
                            .frame(width: 18, height: 18)
                            .background(Color.orange.opacity(0.88))
                            .clipShape(Circle())
                    }
                )
                .buttonStyle(.plain)
            } else if viewModel.canResume {
                Button(
                    action: { viewModel.resumeSession() },
                    label: {
                        Image(systemName: "play.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 9, weight: .bold))
                            .frame(width: 18, height: 18)
                            .background(Color.green.opacity(0.88))
                            .clipShape(Circle())
                    }
                )
                .buttonStyle(.plain)
            } else if viewModel.canStartNext {
                Button(
                    action: { viewModel.startNextSession() },
                    label: {
                        Image(systemName: "forward.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 9, weight: .bold))
                            .frame(width: 18, height: 18)
                            .background(Color.blue.opacity(0.88))
                            .clipShape(Circle())
                    }
                )
                .buttonStyle(.plain)
            }

            Button(
                action: { viewModel.resetSession() },
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

    @ViewBuilder
    private var compactLeadingDisplay: some View {
        if viewModel.canStart {
            Text(viewModel.presetSettings.displayName(for: viewModel.selectedPreset))
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white.opacity(0.68))
        } else {
            countdownDisplay(
                mode: viewModel.presetSettings.countdownDisplayMode,
                size: compactRingSize,
                fontSize: 13
            )
        }
    }

    @ViewBuilder
    private var compactPrimaryActionButton: some View {
        if viewModel.canStart {
            Button(
                action: { viewModel.startSession() },
                label: {
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(Color.green.opacity(0.85)))
                }
            )
            .buttonStyle(.plain)
        } else if viewModel.canStartNext {
            Button(
                action: { viewModel.startNextSession() },
                label: {
                    Image(systemName: "forward.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(Color.blue.opacity(0.88)))
                }
            )
            .buttonStyle(.plain)
            .help("Start \(viewModel.currentSessionType)")
        } else if viewModel.canPause {
            Button(
                action: { viewModel.pauseSession() },
                label: {
                    Image(systemName: "pause.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(Color.orange.opacity(0.88)))
                }
            )
            .buttonStyle(.plain)
            .help("Pause")
        } else if viewModel.canResume {
            Button(
                action: { viewModel.resumeSession() },
                label: {
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(Color.green.opacity(0.88)))
                }
            )
            .buttonStyle(.plain)
            .help("Resume")
        }
    }
}
