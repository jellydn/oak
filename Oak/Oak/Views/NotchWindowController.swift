import AppKit
import Combine
import SwiftUI

// MARK: - NotchWindowController

@MainActor
internal class NotchWindowController: NSWindowController {
    private var lastExpandedState: Bool = false
    private var hasCleanedUp = false
    private var isApplyingFrameChange = false
    private var isFrameUpdateScheduled = false
    private var pendingExpandedState: Bool?
    private var pendingForceReposition = false
    private var pendingTargetOverride: DisplayTarget?
    private let viewModel: FocusSessionViewModel
    private let presetSettings: PresetSettingsStore
    private var displayTargetCancellable: AnyCancellable?
    private var alwaysOnTopCancellable: AnyCancellable?

    convenience init() {
        self.init(presetSettings: nil)
    }

    init(presetSettings: PresetSettingsStore?) {
        let settings = presetSettings ?? PresetSettingsStore.shared
        self.presetSettings = settings
        viewModel = FocusSessionViewModel(presetSettings: settings)

        let window = NotchWindow(
            width: NotchLayout.collapsedWidth,
            height: NotchLayout.height,
            displayTarget: settings.displayTarget,
            preferredDisplayID: settings.preferredDisplayID(for: settings.displayTarget),
            alwaysOnTop: settings.alwaysOnTop
        )
        super.init(window: window)

        let contentView = NotchCompanionView(viewModel: viewModel) { [weak self] expanded in
            self?.handleExpansionChange(expanded)
        }
        let hostingView = NSHostingView(rootView: contentView)
        if #available(macOS 13.0, *) {
            // Notch width/position is controlled by the window controller, not by NSHostingView sizing.
            hostingView.sizingOptions = []
        }
        if #available(macOS 13.3, *) {
            // Borderless notch UI should not react to safe-area changes from AppKit window layout.
            hostingView.safeAreaRegions = []
        }
        window.contentView = hostingView
        window.contentMinSize = NSSize(width: NotchLayout.collapsedWidth, height: NotchLayout.height)
        window.contentMaxSize = NSSize(width: NotchLayout.expandedWidth, height: NotchLayout.height)
        setExpanded(false, forceReposition: true, targetOverride: settings.displayTarget)

        window.orderFrontRegardless()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        displayTargetCancellable = settings.$displayTarget
            .sink { [weak self] nextTarget in
                guard let self else { return }
                self.requestFrameUpdate(for: lastExpandedState, forceReposition: true, targetOverride: nextTarget)
            }

        alwaysOnTopCancellable = settings.$alwaysOnTop
            .sink { [weak self] isAlwaysOnTop in
                guard let self, let window = self.window as? NotchWindow else { return }
                window.level = isAlwaysOnTop ? .statusBar : .floating
                self.requestFrameUpdate(for: self.lastExpandedState, forceReposition: true)
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
    }

    func cleanup() {
        guard !hasCleanedUp else { return }
        hasCleanedUp = true
        displayTargetCancellable?.cancel()
        alwaysOnTopCancellable?.cancel()
        viewModel.cleanup()
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
            self.isFrameUpdateScheduled = false
            guard let expandedState = self.pendingExpandedState else { return }
            let shouldForceReposition = self.pendingForceReposition
            let target = self.pendingTargetOverride

            self.pendingExpandedState = nil
            self.pendingForceReposition = false
            self.pendingTargetOverride = nil

            self.setExpanded(
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

        let targetWidth = expanded ? NotchLayout.expandedWidth : NotchLayout.collapsedWidth
        let activeTarget = targetOverride ?? presetSettings.displayTarget
        let preferredDisplayID = presetSettings.preferredDisplayID(for: activeTarget)
        let resolvedScreen = NSScreen.screen(
            for: activeTarget,
            preferredDisplayID: preferredDisplayID
        )
        let yPosition = notchYPosition(for: resolvedScreen, alwaysOnTop: presetSettings.alwaysOnTop)
        let screenFrame = resolvedScreen?.frame ?? .zero
        let xPosition = screenFrame.midX - (targetWidth / 2)
        let frame = NSRect(x: xPosition, y: yPosition, width: targetWidth, height: NotchLayout.height)

        guard shouldApplyFrameUpdate(current: window.frame, target: frame, forceReposition: forceReposition) else {
            lastExpandedState = expanded
            return
        }

        lastExpandedState = expanded
        isApplyingFrameChange = true
        defer { isApplyingFrameChange = false }
        window.setFrame(frame, display: false, animate: false)
    }

    private func shouldApplyFrameUpdate(current: NSRect, target: NSRect, forceReposition: Bool) -> Bool {
        if forceReposition {
            return true
        }

        return abs(current.minX - target.minX) > 0.5 ||
            abs(current.minY - target.minY) > 0.5 ||
            abs(current.width - target.width) > 0.5 ||
            abs(current.height - target.height) > 0.5
    }

    private func notchYPosition(for screen: NSScreen?, alwaysOnTop: Bool) -> CGFloat {
        return NotchWindow.calculateYPosition(for: screen, height: NotchLayout.height, alwaysOnTop: alwaysOnTop)
    }
}

// MARK: - NotchWindow

internal class NotchWindow: NSPanel {
    init(
        width: CGFloat,
        height: CGFloat,
        displayTarget: DisplayTarget,
        preferredDisplayID: CGDirectDisplayID?,
        alwaysOnTop: Bool = false
    ) {
        let screen = NSScreen.screen(for: displayTarget, preferredDisplayID: preferredDisplayID)
        let screenFrame = screen?.frame ?? .zero
        let xPosition = screenFrame.midX - (width / 2)
        let yPosition = Self.calculateYPosition(for: screen, height: height, alwaysOnTop: alwaysOnTop)

        super.init(
            contentRect: NSRect(x: xPosition, y: yPosition, width: width, height: height),
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

    /// Calculate Y position for notch-first UI
    /// - Parameters:
    ///   - screen: The target screen
    ///   - height: The window height
    ///   - alwaysOnTop: Whether the window should be always on top
    /// - Returns: The calculated Y position
    internal static func calculateYPosition(for screen: NSScreen?, height: CGFloat, alwaysOnTop: Bool) -> CGFloat {
        guard let screen = screen else { return 0 }
        
        // For notch-first UI: position at top of screen if display has a notch
        if screen.hasNotch {
            return screen.frame.maxY - height
        }
        
        // For non-notched displays: position below menu bar if alwaysOnTop, otherwise at top of screen
        if alwaysOnTop {
            return screen.visibleFrame.maxY - height
        }
        return screen.frame.maxY - height
    }
}
