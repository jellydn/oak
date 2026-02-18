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
            presetSelector
        } else if viewModel.autoStartCountdown > 0 {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(viewModel.autoStartCountdown)")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.blue.opacity(0.95))
                    Text("starting...")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.62))
                }
                Text("Next: \(viewModel.currentSessionType)")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white.opacity(0.52))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "Auto-starting \(viewModel.currentSessionType) in \(viewModel.autoStartCountdown) seconds"
            )
            .accessibilityIdentifier("autoStartCountdown")
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Time remaining: \(viewModel.displayTime), \(viewModel.currentSessionType)")
                .accessibilityValue(viewModel.isPaused ? "Paused" : "Running")
            }
        }
    }

    @ViewBuilder
    private var insideNotchExpandedPrimaryControls: some View {
        if viewModel.canStart {
            Button(
                action: { viewModel.startSession(using: presetSelection) },
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
            .accessibilityLabel("Start session")
            .accessibilityHint("Starts a focus session with the selected preset")
            .accessibilityIdentifier("startButton")
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
                .accessibilityLabel("Pause session")
                .accessibilityIdentifier("pauseButton")
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
                .accessibilityLabel("Resume session")
                .accessibilityIdentifier("resumeButton")
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
                .accessibilityLabel("Start next session")
                .accessibilityHint("Starts the next session: \(viewModel.currentSessionType)")
                .accessibilityIdentifier("startNextButton")
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
            .accessibilityLabel("Stop and reset")
            .accessibilityHint("Stops the current session and resets the timer")
            .accessibilityIdentifier("stopButton")
        }
    }

    @ViewBuilder
    private var compactLeadingDisplay: some View {
        if viewModel.canStart {
            Button(
                action: {
                    presetSelection = presetSelection == .short ? .long : .short
                },
                label: {
                    Text(presetLabel(for: presetSelection))
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white.opacity(0.68))
                }
            )
            .buttonStyle(.plain)
            .accessibilityLabel("Toggle preset: \(presetLabel(for: presetSelection))")
            .accessibilityHint("Switches between short and long presets")
            .accessibilityIdentifier("presetToggleButton")
        } else if viewModel.autoStartCountdown > 0 {
            HStack(spacing: 4) {
                Text("\(viewModel.autoStartCountdown)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.blue.opacity(0.95))
                Text("starting...")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white.opacity(0.52))
            }
            .accessibilityLabel("Auto-starting in \(viewModel.autoStartCountdown) seconds")
            .accessibilityIdentifier("autoStartCountdown")
        } else {
            countdownDisplay(
                mode: viewModel.presetSettings.countdownDisplayMode,
                size: compactRingSize,
                fontSize: 13
            )
            .accessibilityLabel("Time remaining: \(viewModel.displayTime)")
            .accessibilityValue(viewModel.isPaused ? "Paused" : "Running")
            .accessibilityIdentifier("countdownDisplay")
        }
    }

    @ViewBuilder
    private var compactPrimaryActionButton: some View {
        if viewModel.canStart {
            Button(
                action: { viewModel.startSession(using: presetSelection) },
                label: {
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(Color.green.opacity(0.85)))
                }
            )
            .buttonStyle(.plain)
            .accessibilityLabel("Start session")
            .accessibilityHint("Starts a focus session with the selected preset")
            .accessibilityIdentifier("startButton")
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
            .accessibilityLabel("Start next session")
            .accessibilityHint("Starts the next session: \(viewModel.currentSessionType)")
            .accessibilityIdentifier("startNextButton")
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
            .accessibilityLabel("Pause session")
            .accessibilityIdentifier("pauseButton")
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
            .accessibilityLabel("Resume session")
            .accessibilityIdentifier("resumeButton")
        }
    }
}
