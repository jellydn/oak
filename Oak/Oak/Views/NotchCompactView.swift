import SwiftUI

internal struct NotchCompactView: View {
    @ObservedObject var viewModel: FocusSessionViewModel
    let presetSelection: Preset
    let contentSpacing: CGFloat
    let compactRingSize: CGFloat
    let onStart: () -> Void
    let onStartNext: () -> Void

    var body: some View {
        HStack(spacing: contentSpacing) {
            if viewModel.canStart {
                Text(presetLabel)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.62))
                Button(
                    action: {
                        onStart()
                    },
                    label: {
                        Image(systemName: "play.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 9, weight: .bold))
                            .frame(width: 16, height: 16)
                            .background(
                                Circle()
                                    .fill(Color.green.opacity(0.85))
                            )
                    }
                )
                .buttonStyle(.plain)
            } else if viewModel.canStartNext {
                countdownDisplay(
                    mode: viewModel.presetSettings.countdownDisplayMode,
                    size: compactRingSize,
                    fontSize: 13
                )
                Button(
                    action: {
                        onStartNext()
                    },
                    label: {
                        Image(systemName: "forward.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 9, weight: .bold))
                            .frame(width: 16, height: 16)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.88))
                            )
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

    private func countdownDisplay(
        mode: CountdownDisplayMode,
        size: CGFloat,
        fontSize: CGFloat
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

    private var presetLabel: String {
        viewModel.presetSettings.displayName(for: presetSelection)
    }
}
