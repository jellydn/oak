import AppKit
import Combine
import SwiftUI

@MainActor
internal class NotchWindowController: NSWindowController {
    private var lastExpandedState: Bool = false
    private var hasCleanedUp = false
    private var isApplyingFrameChange = false
    private var isFrameUpdateScheduled = false
    private var pendingExpandedState: Bool?
    private var pendingForceReposition = false
    private var pendingTargetOverride: DisplayTarget?
    internal private(set) var viewModel: FocusSessionViewModel
    private let presetSettings: PresetSettingsStore
    private let notificationService: NotificationService
    private let sparkleUpdater: SparkleUpdater
    private let keyboardShortcutService: KeyboardShortcutService
    private var displayTargetCancellable: AnyCancellable?
    private var alwaysOnTopCancellable: AnyCancellable?
    private var showBelowNotchCancellable: AnyCancellable?

    init(
        presetSettings: PresetSettingsStore,
        notificationService: NotificationService,
        sparkleUpdater: SparkleUpdater,
        keyboardShortcutService: KeyboardShortcutService = KeyboardShortcutService()
    ) {
        self.presetSettings = presetSettings
        self.notificationService = notificationService
        self.sparkleUpdater = sparkleUpdater
        self.keyboardShortcutService = keyboardShortcutService
        viewModel = FocusSessionViewModel(
            presetSettings: presetSettings,
            notificationService: notificationService
        )
        let initialWidths = WindowPositioning.initialWidths(for: presetSettings)

        let window = NotchWindow(
            width: initialWidths.collapsed,
            height: NotchLayout.height,
            displayTarget: presetSettings.displayTarget,
            preferredDisplayID: presetSettings.preferredDisplayID(for: presetSettings.displayTarget),
            alwaysOnTop: presetSettings.alwaysOnTop,
            showBelowNotch: presetSettings.showBelowNotch
        )
        super.init(window: window)

        setupWindowContent(in: window)
        setupBindings()

        setExpanded(false, forceReposition: true, targetOverride: presetSettings.displayTarget)
        window.orderFrontRegardless()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private func setupWindowContent(in window: NotchWindow) {
        let contentView = NotchCompanionView(
            viewModel: viewModel,
            notificationService: notificationService,
            sparkleUpdater: sparkleUpdater,
            keyboardShortcutService: keyboardShortcutService
        ) { [weak self] expanded in
            self?.handleExpansionChange(expanded)
        }
        let hostingView = NSHostingView(rootView: contentView)
        if #available(macOS 13.0, *) {
            hostingView.sizingOptions = []
        }
        if #available(macOS 13.3, *) {
            hostingView.safeAreaRegions = []
        }
        window.contentView = hostingView

        let initialWidths = WindowPositioning.initialWidths(for: presetSettings)
        window.contentMinSize = NSSize(width: initialWidths.collapsed, height: NotchLayout.height)
        window.contentMaxSize = NSSize(width: initialWidths.expanded, height: NotchLayout.height)
    }

    private func setupBindings() {
        displayTargetCancellable = presetSettings.$displayTarget
            .sink { [weak self] nextTarget in
                guard let self else { return }
                requestFrameUpdate(for: lastExpandedState, forceReposition: true, targetOverride: nextTarget)
            }

        alwaysOnTopCancellable = presetSettings.$alwaysOnTop
            .sink { [weak self] isAlwaysOnTop in
                guard let self, let window = window as? NotchWindow else { return }
                window.level = isAlwaysOnTop ? .statusBar : .floating
                requestFrameUpdate(for: lastExpandedState, forceReposition: true)
            }

        showBelowNotchCancellable = presetSettings.$showBelowNotch
            .sink { [weak self] _ in
                guard let self else { return }
                requestFrameUpdate(for: lastExpandedState, forceReposition: true)
            }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        let vm = viewModel
        Task { @MainActor in
            vm.cleanup()
        }
        NotificationCenter.default.removeObserver(self)
        displayTargetCancellable?.cancel()
        alwaysOnTopCancellable?.cancel()
        showBelowNotchCancellable?.cancel()
    }

    func cleanup() {
        guard !hasCleanedUp else { return }
        hasCleanedUp = true
        displayTargetCancellable?.cancel()
        alwaysOnTopCancellable?.cancel()
        showBelowNotchCancellable?.cancel()
        viewModel.cleanup()
    }

    func checkDayChange() {
        viewModel.progressManager.checkDayChange()
    }

    @objc private func screenConfigurationChanged() {
        requestFrameUpdate(for: lastExpandedState, forceReposition: true)
    }

    func handleExpansionChange(_ expanded: Bool) {
        requestFrameUpdate(for: expanded)
    }

    private func requestFrameUpdate(
        for expanded: Bool,
        forceReposition: Bool = false,
        targetOverride: DisplayTarget? = nil
    ) {
        pendingExpandedState = expanded
        pendingForceReposition = pendingForceReposition || forceReposition
        if let targetOverride {
            pendingTargetOverride = targetOverride
        }

        guard !isFrameUpdateScheduled else { return }
        isFrameUpdateScheduled = true

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            isFrameUpdateScheduled = false
            guard let expandedState = pendingExpandedState else { return }
            let shouldForceReposition = pendingForceReposition
            let target = pendingTargetOverride

            pendingExpandedState = nil
            pendingForceReposition = false
            pendingTargetOverride = nil

            setExpanded(
                expandedState,
                forceReposition: shouldForceReposition,
                targetOverride: target
            )
        }
    }

    private func setExpanded(
        _ expanded: Bool,
        forceReposition: Bool = false,
        targetOverride: DisplayTarget? = nil
    ) {
        guard let window else { return }
        guard !isApplyingFrameChange else { return }
        guard forceReposition || lastExpandedState != expanded else { return }

        let activeTarget = targetOverride ?? presetSettings.displayTarget
        let preferredDisplayID = presetSettings.preferredDisplayID(for: activeTarget)
        let resolvedScreen = NSScreen.screen(
            for: activeTarget,
            preferredDisplayID: preferredDisplayID
        )
        let widths = WindowPositioning.widths(for: resolvedScreen, showBelowNotch: presetSettings.showBelowNotch)
        window.contentMinSize = NSSize(width: widths.collapsed, height: NotchLayout.height)
        window.contentMaxSize = NSSize(width: widths.expanded, height: NotchLayout.height)

        let targetWidth = expanded ? widths.expanded : widths.collapsed
        let frame = WindowPositioning.calculateFrame(
            screen: resolvedScreen,
            width: targetWidth,
            height: NotchLayout.height,
            alwaysOnTop: presetSettings.alwaysOnTop,
            showBelowNotch: presetSettings.showBelowNotch
        )

        guard WindowPositioning.shouldApplyFrameUpdate(
            current: window.frame,
            target: frame,
            forceReposition: forceReposition
        ) else {
            lastExpandedState = expanded
            return
        }

        lastExpandedState = expanded
        isApplyingFrameChange = true
        defer { isApplyingFrameChange = false }
        window.setFrame(frame, display: false, animate: false)
    }
}

// MARK: - NotchWindow

internal class NotchWindow: NSPanel {
    init(
        width: CGFloat,
        height: CGFloat,
        displayTarget: DisplayTarget,
        preferredDisplayID: CGDirectDisplayID?,
        alwaysOnTop: Bool = false,
        showBelowNotch: Bool = false
    ) {
        let screen = NSScreen.screen(for: displayTarget, preferredDisplayID: preferredDisplayID)
        let frame = WindowPositioning.calculateFrame(
            screen: screen,
            width: width,
            height: height,
            alwaysOnTop: alwaysOnTop,
            showBelowNotch: showBelowNotch
        )

        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = alwaysOnTop ? .statusBar : .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = false
    }
}
