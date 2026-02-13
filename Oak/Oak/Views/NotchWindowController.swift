import AppKit
import Combine
import SwiftUI

// MARK: - NotchWindowController

@MainActor
internal class NotchWindowController: NSWindowController {
    private let collapsedWidth: CGFloat = 144
    private let expandedWidth: CGFloat = 372
    private let notchHeight: CGFloat = 33
    private var lastExpandedState: Bool = false
    private var hasCleanedUp = false
    private let viewModel: FocusSessionViewModel
    private let presetSettings: PresetSettingsStore
    private var displayTargetCancellable: AnyCancellable?

    convenience init() {
        self.init(presetSettings: nil)
    }

    init(presetSettings: PresetSettingsStore?) {
        let settings = presetSettings ?? PresetSettingsStore.shared
        self.presetSettings = settings
        viewModel = FocusSessionViewModel(presetSettings: settings)

        let window = NotchWindow(
            width: 144,
            height: 33,
            displayTarget: settings.displayTarget,
            preferredDisplayID: settings.preferredDisplayID(for: settings.displayTarget)
        )
        super.init(window: window)

        let contentView = NotchCompanionView(viewModel: viewModel) { [weak self] expanded in
            self?.handleExpansionChange(expanded)
        }
        window.contentView = NSHostingView(rootView: contentView)
        window.contentMinSize = NSSize(width: collapsedWidth, height: notchHeight)
        window.contentMaxSize = NSSize(width: expandedWidth, height: notchHeight)
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
                self.setExpanded(lastExpandedState, forceReposition: true, targetOverride: nextTarget)
            }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        displayTargetCancellable?.cancel()
    }

    func cleanup() {
        guard !hasCleanedUp else { return }
        hasCleanedUp = true
        displayTargetCancellable?.cancel()
        viewModel.cleanup()
    }

    @objc private func screenConfigurationChanged() {
        setExpanded(lastExpandedState, forceReposition: true)
    }

    func handleExpansionChange(_ expanded: Bool) {
        setExpanded(expanded)
    }

    private func setExpanded(
        _ expanded: Bool,
        forceReposition: Bool = false,
        targetOverride: DisplayTarget? = nil
    ) {
        guard let window else { return }
        guard forceReposition || lastExpandedState != expanded else { return }
        lastExpandedState = expanded

        let targetWidth = expanded ? expandedWidth : collapsedWidth
        let activeTarget = targetOverride ?? presetSettings.displayTarget
        let preferredDisplayID = presetSettings.preferredDisplayID(for: activeTarget)
        let resolvedScreen = NSScreen.screen(
            for: activeTarget,
            preferredDisplayID: preferredDisplayID
        )
        let screenFrame = resolvedScreen?.frame ?? .zero
        let yPosition = screenFrame.maxY - notchHeight
        let xPosition = screenFrame.midX - (targetWidth / 2)
        let frame = NSRect(x: xPosition, y: yPosition, width: targetWidth, height: notchHeight)
        window.setFrame(frame, display: true, animate: false)
    }
}

// MARK: - NotchWindow

internal class NotchWindow: NSPanel {
    init(width: CGFloat, height: CGFloat, displayTarget: DisplayTarget, preferredDisplayID: CGDirectDisplayID?) {
        let screenFrame = NSScreen.screen(for: displayTarget, preferredDisplayID: preferredDisplayID)?.frame ?? .zero
        let xPosition = screenFrame.midX - (width / 2)

        super.init(
            contentRect: NSRect(x: xPosition, y: screenFrame.maxY - height, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = false
    }
}
