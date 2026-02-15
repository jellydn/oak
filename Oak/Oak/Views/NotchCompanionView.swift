import SwiftUI

internal struct NotchCompanionView: View {
    let onExpansionChanged: (Bool) -> Void
    @StateObject var viewModel: FocusSessionViewModel
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var sparkleUpdater = SparkleUpdater.shared
    @State private var showAudioMenu = false
    @State private var showProgressMenu = false
    @State private var showSettingsMenu = false
    @State private var animateCompletion: Bool = false
    @State private var showConfetti: Bool = false
    @State private var isExpandedByToggle = false
    @State private var lastReportedExpansion: Bool?
    @State private var presetSelection: Preset = .short
    private let horizontalPadding: CGFloat = 8
    private let verticalPadding: CGFloat = 5
    private let contentSpacing: CGFloat = 10
    private let controlSize: CGFloat = 20
    private let compactRingSize: CGFloat = 20
    private let expandedRingSize: CGFloat = 26

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

    var isExpanded: Bool {
        isExpandedByToggle
    }

    private var containerShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: visualStyle.cornerRadius, style: .continuous)
    }

    var visualStyle: NotchVisualStyle {
        NotchVisualStyle.make(isExpanded: isExpanded, viewModel: viewModel)
    }

    var body: some View {
        ZStack {
            containerShape
                .fill(
                    LinearGradient(
                        colors: visualStyle.backgroundColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    containerShape
                        .stroke(visualStyle.borderColor, lineWidth: visualStyle.borderWidth)
                )
                .shadow(color: visualStyle.shadowColor, radius: visualStyle.shadowRadius, x: 0, y: 4)

            HStack(spacing: contentSpacing) {
                if isInsideNotchExpandedMode {
                    insideNotchExpandedView
                } else if isExpanded {
                    HStack(spacing: contentSpacing) {
                        if viewModel.canStart {
                            startView
                        } else {
                            sessionView
                        }

                        Spacer(minLength: 20)

                        Rectangle()
                            .fill(visualStyle.dividerColor)
                            .frame(width: 1, height: controlSize)
                        HStack(spacing: 6) {
                            audioButton
                            progressButton
                            settingsButton
                        }
                    }
                } else if isInsideNotchCompactMode {
                    insideNotchCompactView
                } else {
                    compactView
                }
                if !isInsideNotchCompactMode, !isInsideNotchExpandedMode {
                    expandToggleButton
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding + (visualStyle.isInsideNotchStyle ? 1 : 0))
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
                notificationService: notificationService,
                sparkleUpdater: sparkleUpdater
            )
            .frame(width: 340)
        }
    }
}

extension NotchCompanionView {
    var compactView: some View {
        HStack(spacing: contentSpacing) {
            if viewModel.canStart {
                Text(visualStyle.isInsideNotchStyle ? "Focus" : presetLabel(for: presetSelection))
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
                countdownDisplay(
                    mode: viewModel.presetSettings.countdownDisplayMode,
                    size: compactRingSize,
                    fontSize: 13
                )
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
}

extension NotchCompanionView {
    var audioButton: some View {
        Button(
            action: {
                showAudioMenu.toggle()
            },
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
            action: {
                showProgressMenu.toggle()
            },
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
            action: {
                showSettingsMenu.toggle()
            },
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
