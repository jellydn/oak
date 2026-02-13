import SwiftUI

// swiftlint:disable type_body_length
internal struct NotchCompanionView: View {
    let onExpansionChanged: (Bool) -> Void

    @StateObject private var viewModel: FocusSessionViewModel
    @StateObject private var notificationService = NotificationService.shared
    @State private var showAudioMenu = false
    @State private var showProgressMenu = false
    @State private var showSettingsMenu = false
    @State private var animateCompletion: Bool = false
    @State private var showConfetti: Bool = false
    @State private var isExpandedByToggle = false
    @State private var lastReportedExpansion: Bool?
    @State private var presetSelection: Preset = .short
    private let horizontalPadding: CGFloat = 6
    private let verticalPadding: CGFloat = 4
    private let contentSpacing: CGFloat = 8
    private let controlSize: CGFloat = 18

    init(
        viewModel: FocusSessionViewModel,
        onExpansionChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onExpansionChanged = onExpansionChanged
    }

    @MainActor
    init(onExpansionChanged: @escaping (Bool) -> Void = { _ in }) {
        _viewModel = StateObject(wrappedValue: FocusSessionViewModel())
        self.onExpansionChanged = onExpansionChanged
    }

    private var isExpanded: Bool {
        isExpandedByToggle
    }

    private var containerShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
    }

    var body: some View {
        ZStack {
            containerShape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.78),
                            Color(red: 0.13, green: 0.14, blue: 0.18).opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    containerShape
                        .stroke(
                            viewModel.isSessionComplete ? Color.green.opacity(0.45) : Color.white.opacity(0.14),
                            lineWidth: viewModel.isSessionComplete ? 1.4 : 1
                        )
                )
                .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)

            HStack(spacing: contentSpacing) {
                if isExpanded {
                    if viewModel.canStart {
                        startView
                    } else {
                        sessionView
                    }

                    audioButton
                    progressButton
                    settingsButton
                } else {
                    compactView
                }

                expandToggleButton
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .scaleEffect(animateCompletion ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: animateCompletion)

            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .frame(height: NotchLayout.height)
        .contentShape(Rectangle())
        .onChange(of: isExpanded) { expanded in
            notifyExpansionChanged(expanded)
        }
        .onAppear {
            notifyExpansionChanged(isExpanded)
            presetSelection = viewModel.selectedPreset
        }
        .onChange(of: viewModel.isSessionComplete) { isComplete in
            if isComplete {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    animateCompletion = true
                }

                // Show confetti only for completed work sessions
                if case let .completed(isWorkSession) = viewModel.sessionState, isWorkSession {
                    showConfetti = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + ConfettiView.animationDuration) {
                        showConfetti = false
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        animateCompletion = false
                    }
                }
            }
        }
        .popover(isPresented: $showAudioMenu) {
            AudioMenuView(audioManager: viewModel.audioManager)
                .frame(width: 200)
        }
        .popover(isPresented: $showProgressMenu) {
            ProgressMenuView(viewModel: viewModel)
                .frame(width: 200)
        }
        .popover(isPresented: $showSettingsMenu) {
            SettingsMenuView(
                presetSettings: viewModel.presetSettings,
                notificationService: notificationService
            )
            .frame(width: 280)
        }
        .contextMenu {
            if #available(macOS 14.0, *) {
                SettingsLink {
                    Text("Settings...")
                }
            } else {
                Button("Settings...") {
                    NSApp.sendAction(NSSelectorFromString("showSettingsWindow:"), to: nil, from: nil)
                }
            }

            Divider()

            Button("Quit Oak") {
                NSApp.terminate(nil)
            }
        }
    }

    private var compactView: some View {
        HStack(spacing: contentSpacing) {
            if viewModel.canStart {
                Text(presetLabel(for: presetSelection))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.62))

                Button(
                    action: {
                        viewModel.startSession(using: presetSelection)
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
                countdownDisplay(size: 20, fontSize: 13)

                Button(
                    action: {
                        viewModel.startNextSession()
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
                countdownDisplay(size: 20, fontSize: 13)
            }
        }
    }

    private func countdownDisplay(size: CGFloat, fontSize: CGFloat) -> some View {
        Group {
            if viewModel.presetSettings.countdownDisplayMode == .circleRing {
                ZStack {
                    CircularProgressRing(
                        progress: viewModel.progressPercentage,
                        lineWidth: 2.5,
                        ringColor: viewModel.isPaused ? .orange : .white,
                        backgroundColor: .white.opacity(0.2)
                    )
                    .frame(width: size, height: size)

                    Text(viewModel.displayTime)
                        .font(.system(size: fontSize * 0.4, weight: .semibold, design: .monospaced))
                        .foregroundColor(viewModel.isPaused ? Color.orange.opacity(0.95) : Color.white.opacity(0.95))
                }
            } else {
                Text(viewModel.displayTime)
                    .font(.system(size: fontSize, weight: .semibold, design: .monospaced))
                    .foregroundColor(viewModel.isPaused ? Color.orange.opacity(0.95) : Color.white.opacity(0.95))
            }
        }
    }

    private var startView: some View {
        HStack(spacing: 6) {
            presetSelector

            Button(
                action: {
                    viewModel.startSession(using: presetSelection)
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
            if viewModel.presetSettings.countdownDisplayMode == .circleRing {
                VStack(alignment: .leading, spacing: 2) {
                    ZStack {
                        CircularProgressRing(
                            progress: viewModel.progressPercentage,
                            lineWidth: 2.5,
                            ringColor: viewModel.isPaused ? .orange : .white,
                            backgroundColor: .white.opacity(0.2)
                        )
                        .frame(width: 28, height: 28)

                        Text(viewModel.displayTime)
                            .font(.system(size: 6, weight: .semibold, design: .monospaced))
                            .foregroundColor(viewModel.isPaused ? Color.orange.opacity(0.95) : Color.white.opacity(0.95))
                    }

                    Text(viewModel.currentSessionType)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.52))
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.displayTime)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(viewModel.isPaused ? Color.orange.opacity(0.95) : Color.white.opacity(0.95))

                    Text(viewModel.currentSessionType)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.52))
                }
            }

            if viewModel.canPause {
                Button(
                    action: {
                        viewModel.pauseSession()
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
                        viewModel.resumeSession()
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
                        viewModel.startNextSession()
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
                    viewModel.resetSession()
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

    private var audioButton: some View {
        Button(
            action: {
                showAudioMenu.toggle()
            },
            label: {
                ZStack {
                    Circle()
                        .fill(viewModel.audioManager.isPlaying ? Color.blue.opacity(0.25) : Color.white.opacity(0.08))
                        .frame(width: controlSize, height: controlSize)

                    Image(systemName: viewModel.audioManager.selectedTrack.systemImageName)
                        .foregroundColor(viewModel.audioManager.isPlaying ? .blue : .white.opacity(0.7))
                        .font(.system(size: 9))
                }
            }
        )
        .buttonStyle(.plain)
    }

    private var progressButton: some View {
        Button(
            action: {
                showProgressMenu.toggle()
            },
            label: {
                ZStack {
                    Circle()
                        .fill(viewModel.streakDays > 0 ? Color.orange.opacity(0.24) : Color.white.opacity(0.08))
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

    private var settingsButton: some View {
        Button(
            action: {
                showSettingsMenu.toggle()
            },
            label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
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

    private var expandToggleButton: some View {
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
                            .fill(Color.white.opacity(0.08))
                    )
            }
        )
        .buttonStyle(.plain)
        .contentShape(Circle())
        .help(isExpanded ? "Collapse" : "Expand")
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
                presetSelection = preset
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

    private func presetLabel(for preset: Preset) -> String {
        viewModel.presetSettings.displayName(for: preset)
    }

    private func notifyExpansionChanged(_ expanded: Bool) {
        guard lastReportedExpansion != expanded else { return }
        lastReportedExpansion = expanded

        DispatchQueue.main.async {
            onExpansionChanged(expanded)
        }
    }
}

// swiftlint:enable type_body_length
