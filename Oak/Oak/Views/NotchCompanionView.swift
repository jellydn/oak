import AppKit
import SwiftUI

internal struct NotchCompanionView: View {
    let onExpansionChanged: (Bool) -> Void
    @ObservedObject var viewModel: FocusSessionViewModel
    @ObservedObject private var notificationService: NotificationService
    @ObservedObject private var sparkleUpdater: SparkleUpdater
    @State var showAudioMenu = false
    @State var showProgressMenu = false
    @State var showSettingsMenu = false
    @State private var animateCompletion: Bool = false
    @State private var showConfetti: Bool = false
    @State var isExpandedByToggle = false
    @State var lastReportedExpansion: Bool?
    @State var presetSelection: Preset = .short
    @State private var localEventMonitor: Any?
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
        onExpansionChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.viewModel = viewModel
        self.notificationService = notificationService
        self.sparkleUpdater = sparkleUpdater
        self.onExpansionChanged = onExpansionChanged
    }

    var isExpanded: Bool {
        isExpandedByToggle
    }

    private var containerShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: visualStyle.cornerRadius, style: .continuous)
    }

    var visualStyle: NotchVisualStyle {
        NotchVisualStyle.make(isInsideNotch: isInsideNotch)
    }

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
            setupKeyboardMonitoring()
        }
        .onDisappear {
            removeKeyboardMonitoring()
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
                .dismissOnClickOutside { [self] in
                    showAudioMenu = false
                }
        }
        .popover(isPresented: $showProgressMenu) {
            ProgressMenuView(viewModel: viewModel)
                .frame(width: 200)
                .dismissOnClickOutside { [self] in
                    showProgressMenu = false
                }
        }
        .popover(isPresented: $showSettingsMenu) {
            SettingsMenuView(
                presetSettings: viewModel.presetSettings,
                notificationService: notificationService,
                sparkleUpdater: sparkleUpdater
            )
            .frame(width: 340)
            .dismissOnClickOutside { [self] in
                showSettingsMenu = false
            }
        }
    }

    private func setupKeyboardMonitoring() {
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            handleKeyEvent(event)
        }
    }

    private func removeKeyboardMonitoring() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        guard let characters = event.charactersIgnoringModifiers else {
            return event
        }

        // Handle Escape key
        if event.keyCode == 53 {
            return handleEscapeKey()
        }

        // Handle other keys
        switch characters {
        case " ":
            return handleSpaceKey()
        case "\r":
            return handleReturnKey()
        default:
            return event
        }
    }

    private func handleEscapeKey() -> NSEvent? {
        if showAudioMenu || showProgressMenu || showSettingsMenu {
            showAudioMenu = false
            showProgressMenu = false
            showSettingsMenu = false
            return nil
        }

        if !viewModel.canStart {
            viewModel.resetSession()
            return nil
        }

        return nil
    }

    private func handleSpaceKey() -> NSEvent? {
        guard !showAudioMenu && !showProgressMenu && !showSettingsMenu else {
            return nil
        }

        if viewModel.canStart {
            viewModel.startSession(using: presetSelection)
            return nil
        }

        if viewModel.canPause {
            viewModel.pauseSession()
            return nil
        }

        if viewModel.canResume {
            viewModel.resumeSession()
            return nil
        }

        return nil
    }

    private func handleReturnKey() -> NSEvent? {
        guard !showAudioMenu && !showProgressMenu && !showSettingsMenu else {
            return nil
        }

        if viewModel.canStartNext {
            viewModel.startNextSession()
            return nil
        }

        return nil
    }
}
