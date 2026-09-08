import SwiftUI

internal struct NotchCompanionView: View {
    let onExpansionChanged: (Bool) -> Void
    @ObservedObject var viewModel: FocusSessionViewModel
    @ObservedObject private var notificationService: NotificationService
    @ObservedObject private var sparkleUpdater: SparkleUpdater
    private let keyboardShortcutService: KeyboardShortcutService // Passed through; not observed here
    @State var showAudioMenu = false
    @State var isAudioImporterPresented = false
    @State var showProgressMenu = false
    @State var showSettingsMenu = false
    @State private var animateCompletion: Bool = false
    @State private var showConfetti: Bool = false
    @State var isExpandedByToggle = false
    @State var lastReportedExpansion: Bool?
    @State var presetSelection: Preset = .short
    let horizontalPadding: CGFloat = 8
    let verticalPadding: CGFloat = 5
    let contentSpacing: CGFloat = 10
    let controlSize: CGFloat = 20
    let compactRingSize: CGFloat = 20
    let expandedRingSize: CGFloat = 26

    init(
        viewModel: FocusSessionViewModel,
        notificationService: NotificationService,
        sparkleUpdater: SparkleUpdater,
        keyboardShortcutService: KeyboardShortcutService = KeyboardShortcutService(),
        onExpansionChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.viewModel = viewModel
        self.notificationService = notificationService
        self.sparkleUpdater = sparkleUpdater
        self.keyboardShortcutService = keyboardShortcutService
        self.onExpansionChanged = onExpansionChanged
    }

    var isExpanded: Bool {
        isExpandedByToggle
    }

    private var containerShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: visualStyle.cornerRadius, style: .continuous)
    }

    var visualStyle: NotchVisualStyle {
        NotchVisualStyle.make(theme: viewModel.presetSettings.theme, isInsideNotch: isInsideNotch)
    }

    var palette: ThemePalette { viewModel.presetSettings.theme.palette }

    private var isInsideNotch: Bool {
        let settings = viewModel.presetSettings
        let target = settings.displayTarget
        let preferredDisplayID = settings.preferredDisplayID(for: target)
        let targetScreen = NSScreen.screen(for: target, preferredDisplayID: preferredDisplayID)
        return targetScreen?.hasNotch == true && !settings.showBelowNotch
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

            HStack(spacing: contentSpacing) {
                if isInsideNotch {
                    if isExpanded {
                        insideNotchExpandedContent
                    } else {
                        insideNotchCompactContent
                    }
                } else if isExpanded {
                    HStack(spacing: contentSpacing) {
                        if viewModel.canStart {
                            startView
                        } else {
                            sessionView
                        }

                        Spacer(minLength: 12)

                        HStack(spacing: 6) {
                            audioButton
                            progressButton
                            settingsButton
                        }
                    }
                    expandToggleButton
                } else {
                    compactView
                    expandToggleButton
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .scaleEffect(animateCompletion ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: animateCompletion)
            if showConfetti {
                ConfettiView(colors: palette.confettiColors)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: NotchLayout.height)
        .tint(palette.accent)
        .preferredColorScheme(.dark)
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
    }
}

// MARK: - Controls

extension NotchCompanionView {
    var presetToggleButton: some View {
        Button(
            action: {
                presetSelection = presetSelection == .short ? .long : .short
            },
            label: {
                HStack(spacing: 2) {
                    Text(presetLabel(for: presetSelection))
                        .font(.system(size: 9, weight: .semibold))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 6, weight: .semibold))
                }
                .foregroundColor(palette.secondaryForeground)
            }
        )
        .buttonStyle(.plain)
        .accessibilityLabel("Toggle preset: \(presetLabel(for: presetSelection))")
        .accessibilityHint("Switches between short and long presets")
        .accessibilityIdentifier("presetToggleButton")
    }

    var audioButton: some View {
        Button(
            action: { showAudioMenu.toggle() },
            label: {
                ZStack {
                    Circle()
                        .fill(
                            viewModel.audioManager.isPlaying
                                ? palette.accent.opacity(isExpanded ? 0.25 : 0.34)
                                : palette.foreground.opacity(visualStyle.neutralControlOpacity)
                        )
                        .frame(width: controlSize, height: controlSize)

                    Image(systemName: viewModel.audioManager.selectedSound.systemImageName)
                        .foregroundColor(
                            viewModel.audioManager.isPlaying ? palette.accent : palette.secondaryForeground
                        )
                        .font(.system(size: 9))
                }
            }
        )
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.audioManager.isPlaying ? "Audio playing" : "Audio")
        .accessibilityHint("Opens audio menu to select ambient sounds")
        .accessibilityIdentifier("audioButton")
        .popover(isPresented: $showAudioMenu) {
            AudioMenuView(
                audioManager: viewModel.audioManager,
                isImporting: $isAudioImporterPresented,
                theme: viewModel.presetSettings.theme
            )
                .frame(width: 280)
                .dismissOnClickOutside(isDismissalSuppressed: $isAudioImporterPresented) { [self] in
                    showAudioMenu = false
                }
        }
    }

    var progressButton: some View {
        Button(
            action: { showProgressMenu.toggle() },
            label: {
                ZStack {
                    Circle()
                        .fill(
                            viewModel.streakDays > 0
                                ? palette.warning.opacity(isExpanded ? 0.24 : 0.34)
                                : palette.foreground.opacity(visualStyle.neutralControlOpacity)
                        )
                        .frame(width: controlSize, height: controlSize)

                    if viewModel.streakDays > 0 {
                        Text("\(viewModel.streakDays)")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(palette.warning)
                    } else {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(palette.secondaryForeground)
                            .font(.system(size: 9))
                    }
                }
            }
        )
        .buttonStyle(.plain)
        .accessibilityLabel(
            viewModel.streakDays > 0
                ? "Progress: \(viewModel.streakDays) day streak"
                : "Progress"
        )
        .accessibilityHint("Opens progress menu to view session history")
        .accessibilityIdentifier("progressButton")
        .popover(isPresented: $showProgressMenu) {
            ProgressMenuView(viewModel: viewModel)
                .frame(width: 200)
                .dismissOnClickOutside { [self] in
                    showProgressMenu = false
                }
        }
    }

    var settingsButton: some View {
        Button(
            action: { showSettingsMenu.toggle() },
            label: {
                ZStack {
                    Circle()
                        .fill(palette.foreground.opacity(visualStyle.neutralControlOpacity))
                        .frame(width: controlSize, height: controlSize)

                    Image(systemName: "gearshape.fill")
                        .foregroundColor(palette.secondaryForeground)
                        .font(.system(size: 9))
                }
            }
        )
        .buttonStyle(.plain)
        .help("Settings")
        .accessibilityLabel("Settings")
        .accessibilityHint("Opens settings menu")
        .accessibilityIdentifier("settingsButton")
        .popover(isPresented: $showSettingsMenu) {
            SettingsMenuView(
                presetSettings: viewModel.presetSettings,
                notificationService: notificationService,
                sparkleUpdater: sparkleUpdater,
                keyboardShortcutService: keyboardShortcutService,
                progressManager: viewModel.progressManager
            )
            .frame(width: 340)
            .dismissOnClickOutside { [self] in
                showSettingsMenu = false
            }
        }
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
                    .foregroundColor(palette.secondaryForeground)
                    .frame(width: controlSize, height: controlSize)
                    .background(
                        Circle()
                            .fill(palette.foreground.opacity(visualStyle.toggleControlOpacity))
                    )
            }
        )
        .buttonStyle(.plain)
        .contentShape(Circle())
        .help(isExpanded ? "Collapse" : "Expand")
        .accessibilityLabel(isExpanded ? "Collapse" : "Expand")
        .accessibilityHint(
            isExpanded ? "Collapses the companion view" : "Expands the companion view to show all controls"
        )
        .accessibilityIdentifier("expandToggleButton")
    }

    var presetSelector: some View {
        HStack(spacing: 2) {
            presetChip(.short)
            presetChip(.long)
        }
        .padding(2)
        .background(
            Capsule(style: .continuous)
                .fill(palette.foreground.opacity(visualStyle.presetCapsuleOpacity))
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Preset selector")
        .accessibilityIdentifier("presetSelector")
    }

    func presetChip(_ preset: Preset) -> some View {
        let isSelected = presetSelection == preset
        let presetName = presetLabel(for: preset)
        return Button(
            action: { presetSelection = preset },
            label: {
                Text(presetName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isSelected ? palette.foreground : palette.secondaryForeground)
                    .frame(minWidth: 54, minHeight: 18)
                    .background(
                        Capsule(style: .continuous)
                            .fill(isSelected ? palette.selectedBackground : Color.clear)
                    )
            }
        )
        .buttonStyle(.plain)
        .accessibilityLabel(presetName)
        .accessibilityHint(isSelected ? "Currently selected preset" : "Select \(presetName) preset")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("presetChip_\(preset == .short ? "short" : "long")")
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
