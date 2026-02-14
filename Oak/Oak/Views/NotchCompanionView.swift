import SwiftUI

internal struct NotchCompanionView: View {
    let onExpansionChanged: (Bool) -> Void
    let onAuxiliaryMenuPresentationChanged: (Bool) -> Void
    @StateObject private var viewModel: FocusSessionViewModel
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
    private let collapsedTopPadding: CGFloat = 0
    private let expandedTopPadding: CGFloat = 0
    private let contentSpacing: CGFloat = 10
    private let controlSize: CGFloat = 20
    private let compactRingSize: CGFloat = 20
    private let expandedRingSize: CGFloat = 26
    init(
        viewModel: FocusSessionViewModel,
        onExpansionChanged: @escaping (Bool) -> Void = { _ in },
        onAuxiliaryMenuPresentationChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onExpansionChanged = onExpansionChanged
        self.onAuxiliaryMenuPresentationChanged = onAuxiliaryMenuPresentationChanged
    }

    @MainActor
    init(
        onExpansionChanged: @escaping (Bool) -> Void = { _ in },
        onAuxiliaryMenuPresentationChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: FocusSessionViewModel())
        self.onExpansionChanged = onExpansionChanged
        self.onAuxiliaryMenuPresentationChanged = onAuxiliaryMenuPresentationChanged
    }

    private var isExpanded: Bool {
        isExpandedByToggle
    }

    private var currentTopPadding: CGFloat {
        isExpanded ? expandedTopPadding : collapsedTopPadding
    }

    var body: some View {
        ZStack(alignment: .top) {
            NotchBackgroundView(
                isExpanded: isExpanded,
                isSessionComplete: viewModel.isSessionComplete,
                onTap: handleBackgroundTap
            )
            mainContent
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, currentTopPadding)
                .scaleEffect(animateCompletion ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: animateCompletion)

            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: isExpanded) { expanded in
            notifyExpansionChanged(expanded)
        }
        .onAppear {
            notifyExpansionChanged(isExpanded)
            notifyAuxiliaryPresentationChanged()
            presetSelection = viewModel.selectedPreset
        }
        .onChange(of: showAudioMenu) { _ in
            notifyAuxiliaryPresentationChanged()
        }
        .onChange(of: showProgressMenu) { _ in
            notifyAuxiliaryPresentationChanged()
        }
        .onChange(of: showSettingsMenu) { _ in
            notifyAuxiliaryPresentationChanged()
        }
        .onChange(of: viewModel.isSessionComplete) { isComplete in
            handleSessionComplete(isComplete)
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

    private var mainContent: some View {
        HStack(spacing: contentSpacing) {
            if isExpanded {
                NotchSessionControlsView(
                    viewModel: viewModel,
                    presetSelection: presetSelection,
                    controlSize: controlSize,
                    expandedRingSize: expandedRingSize,
                    onPresetChange: { preset in
                        presetSelection = preset
                    },
                    onStart: { preset in
                        viewModel.startSession(using: preset)
                    },
                    onPause: {
                        viewModel.pauseSession()
                    },
                    onResume: {
                        viewModel.resumeSession()
                    },
                    onStartNext: {
                        viewModel.startNextSession()
                    },
                    onReset: {
                        viewModel.resetSession()
                    }
                )
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 1, height: controlSize)
                NotchButtonRowView(
                    viewModel: viewModel,
                    controlSize: controlSize,
                    onAudioToggle: {
                        showAudioMenu.toggle()
                    },
                    onProgressToggle: {
                        showProgressMenu.toggle()
                    },
                    onSettingsToggle: {
                        showSettingsMenu.toggle()
                    }
                )
            } else {
                NotchCompactView(
                    viewModel: viewModel,
                    presetSelection: presetSelection,
                    contentSpacing: contentSpacing,
                    compactRingSize: compactRingSize,
                    onStart: {
                        viewModel.startSession(using: presetSelection)
                    },
                    onStartNext: {
                        viewModel.startNextSession()
                    }
                )
            }

            expandToggleButton
        }
    }

    private var expandToggleButton: some View {
        Button(
            action: {
                let shouldExpand = !isExpandedByToggle
                isExpandedByToggle = shouldExpand
                if !shouldExpand {
                    closeAllMenus()
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

    private func handleBackgroundTap() {
        guard !isExpandedByToggle else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
            isExpandedByToggle = true
        }
    }

    private func closeAllMenus() {
        showAudioMenu = false
        showProgressMenu = false
        showSettingsMenu = false
    }

    private func handleSessionComplete(_ isComplete: Bool) {
        guard isComplete else { return }
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

    private func notifyExpansionChanged(_ expanded: Bool) {
        guard lastReportedExpansion != expanded else { return }
        lastReportedExpansion = expanded
        DispatchQueue.main.async {
            onExpansionChanged(expanded)
        }
    }

    private func notifyAuxiliaryPresentationChanged() {
        let isPresented = showAudioMenu || showProgressMenu || showSettingsMenu
        DispatchQueue.main.async {
            onAuxiliaryMenuPresentationChanged(isPresented)
        }
    }
}
