import AppKit
import Combine
import SwiftUI

private typealias CGSConnectionID = UInt
private typealias CGSSpaceID = UInt64

@_silgen_name("_CGSDefaultConnection")
private func cgsDefaultConnection() -> CGSConnectionID

@_silgen_name("CGSSpaceCreate")
private func cgsSpaceCreate(_ connection: CGSConnectionID, _ unknown: Int, _ options: NSDictionary?) -> CGSSpaceID

@_silgen_name("CGSSpaceSetAbsoluteLevel")
private func cgsSpaceSetAbsoluteLevel(_ connection: CGSConnectionID, _ spaceID: CGSSpaceID, _ level: Int)

@_silgen_name("CGSShowSpaces")
private func cgsShowSpaces(_ connection: CGSConnectionID, _ spaces: NSArray)

@_silgen_name("CGSAddWindowsToSpaces")
private func cgsAddWindowsToSpaces(_ connection: CGSConnectionID, _ windows: NSArray, _ spaces: NSArray)

@_silgen_name("CGSRemoveWindowsFromSpaces")
private func cgsRemoveWindowsFromSpaces(_ connection: CGSConnectionID, _ windows: NSArray, _ spaces: NSArray)

private final class NotchSpaceManager {
    static let shared = NotchSpaceManager()

    private let connection: CGSConnectionID
    private let spaceID: CGSSpaceID
    private var attachedWindowNumbers: Set<Int> = []

    private init() {
        connection = cgsDefaultConnection()
        // Must be 1, otherwise desktop composition may behave incorrectly.
        let id = cgsSpaceCreate(connection, 0x1, nil)
        cgsSpaceSetAbsoluteLevel(connection, id, Int(Int32.max))
        cgsShowSpaces(connection, [id] as NSArray)
        spaceID = id
    }

    func attach(window: NSWindow) {
        let windowNumber = window.windowNumber
        guard windowNumber > 0 else { return }
        guard !attachedWindowNumbers.contains(windowNumber) else { return }

        attachedWindowNumbers.insert(windowNumber)
        cgsAddWindowsToSpaces(connection, [windowNumber] as NSArray, [spaceID] as NSArray)
    }

    func detach(window: NSWindow) {
        let windowNumber = window.windowNumber
        guard windowNumber > 0 else { return }
        guard attachedWindowNumbers.contains(windowNumber) else { return }

        attachedWindowNumbers.remove(windowNumber)
        cgsRemoveWindowsFromSpaces(connection, [windowNumber] as NSArray, [spaceID] as NSArray)
    }
}

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
    private var isAuxiliaryMenuPresented = false
    private let viewModel: FocusSessionViewModel
    private let presetSettings: PresetSettingsStore
    private var displayTargetCancellable: AnyCancellable?
    private var alwaysOnTopCancellable: AnyCancellable?
    private var notchPositionModeCancellable: AnyCancellable?

    convenience init() {
        self.init(presetSettings: nil)
    }

    init(presetSettings: PresetSettingsStore?) {
        let settings = presetSettings ?? PresetSettingsStore.shared
        self.presetSettings = settings
        viewModel = FocusSessionViewModel(presetSettings: settings)
        let windowConfiguration = Self.makeInitialWindowConfiguration(from: settings)
        super.init(window: windowConfiguration.window)

        configureWindowContent(
            windowConfiguration.window,
            initialCollapsedSize: windowConfiguration.collapsedSize,
            displayTarget: settings.displayTarget
        )

        windowConfiguration.window.orderFrontRegardless()
        registerScreenChangeObserver()
        bindSettingsObservers(settings)
        attachWindowToNotchSpaceIfNeeded()
    }

    private static func makeInitialWindowConfiguration(
        from settings: PresetSettingsStore
    ) -> (window: NotchWindow, collapsedSize: NSSize) {
        let displayTarget = settings.displayTarget
        let preferredDisplayID = settings.preferredDisplayID(for: displayTarget)
        let initialScreen = NSScreen.screen(for: displayTarget, preferredDisplayID: preferredDisplayID)
        let initialCollapsedSize = NotchWindow.collapsedSize(for: initialScreen)
        let window = NotchWindow(
            width: initialCollapsedSize.width,
            height: initialCollapsedSize.height,
            displayTarget: displayTarget,
            preferredDisplayID: preferredDisplayID,
            alwaysOnTop: settings.alwaysOnTop,
            notchPositionMode: settings.notchPositionMode
        )
        return (window: window, collapsedSize: initialCollapsedSize)
    }

    private func configureWindowContent(
        _ window: NotchWindow,
        initialCollapsedSize: NSSize,
        displayTarget: DisplayTarget
    ) {
        window.contentView = makeHostingView()
        window.contentMinSize = initialCollapsedSize
        window.contentMaxSize = NSSize(
            width: max(NotchLayout.expandedWidth, initialCollapsedSize.width),
            height: initialCollapsedSize.height
        )
        setExpanded(false, forceReposition: true, targetOverride: displayTarget)
    }

    private func makeHostingView() -> NSHostingView<NotchCompanionView> {
        let contentView = NotchCompanionView(
            viewModel: viewModel,
            onExpansionChanged: { [weak self] expanded in
                self?.handleExpansionChange(expanded)
            },
            onAuxiliaryMenuPresentationChanged: { [weak self] isPresented in
                guard let self else { return }
                self.isAuxiliaryMenuPresented = isPresented
                self.applyWindowLevel()
            }
        )
        let hostingView = NSHostingView(rootView: contentView)
        if #available(macOS 13.0, *) {
            // Notch width/position is controlled by the window controller, not by NSHostingView sizing.
            hostingView.sizingOptions = []
        }
        if #available(macOS 13.3, *) {
            // Borderless notch UI should not react to safe-area changes from AppKit window layout.
            hostingView.safeAreaRegions = []
        }
        return hostingView
    }

    private func applyWindowLevel(
        alwaysOnTop: Bool? = nil,
        notchPositionMode: NotchPositionMode? = nil
    ) {
        guard let window = window as? NotchWindow else { return }
        let resolvedAlwaysOnTop = alwaysOnTop ?? presetSettings.alwaysOnTop
        let resolvedNotchPositionMode = notchPositionMode ?? presetSettings.notchPositionMode
        if isAuxiliaryMenuPresented, resolvedNotchPositionMode != .insideNotch {
            // Keep notch panel behind attached popovers to avoid clipped/cut-off popover chrome.
            window.level = .normal
            return
        }

        window.level = NotchWindow.overlayLevel(
            alwaysOnTop: resolvedAlwaysOnTop,
            notchPositionMode: resolvedNotchPositionMode
        )
    }

    private func registerScreenChangeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private func bindSettingsObservers(_ settings: PresetSettingsStore) {
        displayTargetCancellable = settings.$displayTarget
            .sink { [weak self] nextTarget in
                guard let self else { return }
                self.requestFrameUpdate(for: self.lastExpandedState, forceReposition: true, targetOverride: nextTarget)
            }

        alwaysOnTopCancellable = settings.$alwaysOnTop
            .sink { [weak self] isAlwaysOnTop in
                guard let self else { return }
                self.applyWindowLevel(alwaysOnTop: isAlwaysOnTop)
                self.requestFrameUpdate(for: self.lastExpandedState, forceReposition: true)
            }

        notchPositionModeCancellable = settings.$notchPositionMode
            .sink { [weak self] mode in
                guard let self else { return }
                self.applyWindowLevel(notchPositionMode: mode)
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
        notchPositionModeCancellable?.cancel()
    }

    func cleanup() {
        guard !hasCleanedUp else { return }
        hasCleanedUp = true
        if let window {
            NotchSpaceManager.shared.detach(window: window)
        }
        displayTargetCancellable?.cancel()
        alwaysOnTopCancellable?.cancel()
        notchPositionModeCancellable?.cancel()
        viewModel.cleanup()
    }

    @objc private func screenConfigurationChanged() {
        attachWindowToNotchSpaceIfNeeded()
        requestFrameUpdate(for: lastExpandedState, forceReposition: true)
    }

    private func attachWindowToNotchSpaceIfNeeded(retryCount: Int = 0) {
        guard let window else { return }

        if window.windowNumber > 0 {
            NotchSpaceManager.shared.attach(window: window)
            return
        }

        guard retryCount < 8 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.attachWindowToNotchSpaceIfNeeded(retryCount: retryCount + 1)
        }
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

        let activeTarget = targetOverride ?? presetSettings.displayTarget
        let preferredDisplayID = presetSettings.preferredDisplayID(for: activeTarget)
        let resolvedScreen = NSScreen.screen(
            for: activeTarget,
            preferredDisplayID: preferredDisplayID
        )
        let collapsedSize = NotchWindow.collapsedSize(for: resolvedScreen)
        let targetWidth = expanded ? max(NotchLayout.expandedWidth, collapsedSize.width) : collapsedSize.width
        let targetHeight = collapsedSize.height
        window.contentMinSize = collapsedSize
        window.contentMaxSize = NSSize(
            width: max(NotchLayout.expandedWidth, collapsedSize.width),
            height: collapsedSize.height
        )
        let screenFrame = resolvedScreen?.frame ?? .zero
        let notchPositionMode = resolvedFramePositionMode(
            configuredMode: presetSettings.notchPositionMode,
            expanded: expanded
        )
        let yPosition = NotchWindow.yPosition(
            for: resolvedScreen,
            height: targetHeight,
            mode: notchPositionMode
        )
        let xPosition = screenFrame.midX - (targetWidth / 2)
        let frame = NSRect(x: xPosition, y: yPosition, width: targetWidth, height: targetHeight)

        guard shouldApplyFrameUpdate(current: window.frame, target: frame, forceReposition: forceReposition) else {
            lastExpandedState = expanded
            return
        }

        lastExpandedState = expanded
        isApplyingFrameChange = true
        defer { isApplyingFrameChange = false }
        window.setFrame(frame, display: false, animate: false)
        attachWindowToNotchSpaceIfNeeded()
    }

    private func resolvedFramePositionMode(configuredMode: NotchPositionMode, expanded: Bool) -> NotchPositionMode {
        // Expanded content needs to be fully visible; inside-notch placement can be
        // horizontally masked by the menu bar band on some displays.
        if configuredMode == .insideNotch, expanded {
            return .belowNotch
        }
        return configuredMode
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
}

// MARK: - NotchWindow

internal class NotchWindow: NSPanel {
    init(
        width: CGFloat,
        height: CGFloat,
        displayTarget: DisplayTarget,
        preferredDisplayID: CGDirectDisplayID?,
        alwaysOnTop: Bool = false,
        notchPositionMode: NotchPositionMode
    ) {
        let screen = NSScreen.screen(for: displayTarget, preferredDisplayID: preferredDisplayID)
        let screenFrame = screen?.frame ?? .zero
        let xPosition = screenFrame.midX - (width / 2)
        let yPosition = Self.yPosition(for: screen, height: height, mode: notchPositionMode)

        super.init(
            contentRect: NSRect(x: xPosition, y: yPosition, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = Self.overlayLevel(alwaysOnTop: alwaysOnTop, notchPositionMode: notchPositionMode)
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        isFloatingPanel = true
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = false
        hidesOnDeactivate = false
        canHide = false
    }

    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }

    override func constrainFrameRect(_ frameRect: NSRect, to _: NSScreen?) -> NSRect {
        // Keep explicit notch anchoring. The default NSPanel behavior constrains to visibleFrame,
        // which pushes the panel below the built-in notch/menu bar area.
        frameRect
    }

    static func yPosition(for screen: NSScreen?, height: CGFloat, mode: NotchPositionMode) -> CGFloat {
        guard let screen else { return -height }
        return yPosition(
            screenFrame: screen.frame,
            auxiliaryTopLeftArea: screen.auxiliaryTopLeftArea,
            auxiliaryTopRightArea: screen.auxiliaryTopRightArea,
            height: height,
            mode: mode
        )
    }

    static func yPosition(
        screenFrame: NSRect,
        auxiliaryTopLeftArea: NSRect?,
        auxiliaryTopRightArea: NSRect?,
        height: CGFloat,
        mode: NotchPositionMode
    ) -> CGFloat {
        let defaultTopAnchoredY = screenFrame.maxY - height
        if mode == .insideNotch {
            // Match boring.notch behavior: keep the panel top-anchored.
            // Lifting above screen bounds can cause clipping artifacts ("only border visible").
            return defaultTopAnchoredY
        }

        // On notched displays, auxiliary areas indicate the top strips beside the notch.
        // Anchor directly below that strip to keep the panel fully visible.
        if let leftArea = auxiliaryTopLeftArea, let rightArea = auxiliaryTopRightArea {
            let notchBandBottomY = min(leftArea.minY, rightArea.minY)
            return min(defaultTopAnchoredY, notchBandBottomY - height)
        }

        if let leftArea = auxiliaryTopLeftArea {
            return min(defaultTopAnchoredY, leftArea.minY - height)
        }

        if let rightArea = auxiliaryTopRightArea {
            return min(defaultTopAnchoredY, rightArea.minY - height)
        }

        return defaultTopAnchoredY
    }

    static func overlayLevel(alwaysOnTop: Bool, notchPositionMode: NotchPositionMode) -> NSWindow.Level {
        if notchPositionMode == .insideNotch {
            return .mainMenu + 3
        }
        return alwaysOnTop ? .statusBar : .floating
    }

    static func collapsedSize(for screen: NSScreen?) -> NSSize {
        guard let screen else {
            return NSSize(width: NotchLayout.collapsedWidth, height: NotchLayout.height)
        }

        return collapsedSize(
            screenFrame: screen.frame,
            visibleFrame: screen.visibleFrame,
            safeAreaTopInset: screen.safeAreaInsets.top,
            auxiliaryTopLeftArea: screen.auxiliaryTopLeftArea,
            auxiliaryTopRightArea: screen.auxiliaryTopRightArea
        )
    }

    static func collapsedSize(
        screenFrame: NSRect,
        visibleFrame: NSRect,
        safeAreaTopInset: CGFloat,
        auxiliaryTopLeftArea: NSRect?,
        auxiliaryTopRightArea: NSRect?
    ) -> NSSize {
        var notchWidth = NotchLayout.collapsedWidth
        if let topLeftPadding = auxiliaryTopLeftArea?.width, let topRightPadding = auxiliaryTopRightArea?.width {
            notchWidth = max(NotchLayout.collapsedWidth, screenFrame.width - topLeftPadding - topRightPadding + 4)
        }

        let menuBarHeight = screenFrame.maxY - visibleFrame.maxY
        let auxiliaryBandHeight = max(auxiliaryTopLeftArea?.height ?? 0, auxiliaryTopRightArea?.height ?? 0)
        let notchHeight = max(NotchLayout.height, max(menuBarHeight, max(safeAreaTopInset, auxiliaryBandHeight)))

        return NSSize(width: notchWidth, height: notchHeight)
    }
}
