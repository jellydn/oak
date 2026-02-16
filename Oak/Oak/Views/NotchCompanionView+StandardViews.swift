import SwiftUI

internal extension NotchCompanionView {
    var compactView: some View {
        HStack(spacing: contentSpacing) {
            if viewModel.canStart {
                Text(presetLabel(for: presetSelection))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.62))
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
            } else if viewModel.canStartNext {
                if viewModel.autoStartCountdown > 0 {
                    HStack(spacing: 4) {
                        Text("\(viewModel.autoStartCountdown)")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(.blue.opacity(0.95))
                        Text("auto")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.52))
                    }
                } else {
                    countdownDisplay(
                        mode: viewModel.presetSettings.countdownDisplayMode,
                        size: compactRingSize,
                        fontSize: 13
                    )
                }
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
            } else {
                countdownDisplay(
                    mode: viewModel.presetSettings.countdownDisplayMode,
                    size: compactRingSize,
                    fontSize: 13
                )
            }
        }
    }

    func countdownDisplay(
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

    var startView: some View {
        HStack(spacing: 6) {
            presetSelector
            Button(
                action: { viewModel.startSession(using: presetSelection) },
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

    var sessionView: some View {
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
                    countdownDisplay(mode: displayMode, size: expandedRingSize, fontSize: 14)
                    Text(viewModel.currentSessionType)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.52))
                }
            }
            if viewModel.canPause {
                Button(
                    action: { viewModel.pauseSession() },
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
                    action: { viewModel.resumeSession() },
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
                if viewModel.autoStartCountdown > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("\(viewModel.autoStartCountdown)")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.blue.opacity(0.95))
                            Text("auto-starting...")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.white.opacity(0.62))
                        }
                        Text("Next: \(viewModel.currentSessionType)")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.52))
                    }
                }
                Button(
                    action: { viewModel.startNextSession() },
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
}
