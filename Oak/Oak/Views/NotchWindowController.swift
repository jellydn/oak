import AppKit
import Combine
import SwiftUI

// MARK: - Screen Detection Helper

internal extension NSScreen {
    static func screen(for target: DisplayTarget) -> NSScreen? {
        if target == .mainDisplay, let mainScreen = NSScreen.main {
            return mainScreen
        }

        if target == .notchedDisplay {
            for screen in NSScreen.screens where screen.auxiliaryTopLeftArea != nil {
                return screen
            }
        }

        if let mainScreen = NSScreen.main {
            return mainScreen
        }

        for screen in NSScreen.screens where screen.auxiliaryTopLeftArea != nil {
            return screen
        }

        return NSScreen.screens.first
    }
}

// MARK: - NotchWindowController

@MainActor
internal class NotchWindowController: NSWindowController {
    private let collapsedWidth: CGFloat = 144
    private let expandedWidth: CGFloat = 372
    private let notchHeight: CGFloat = 33
    private var lastExpandedState: Bool = false
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

        let window = NotchWindow(width: 144, height: 33, displayTarget: settings.displayTarget)
        super.init(window: window)

        let contentView = NotchCompanionView(viewModel: viewModel) { [weak self] expanded in
            self?.handleExpansionChange(expanded)
        }
        window.contentView = NSHostingView(rootView: contentView)

        window.orderFrontRegardless()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        displayTargetCancellable = settings.$displayTarget
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.setExpanded(self?.lastExpandedState ?? false, forceReposition: true)
            }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func cleanup() {
        viewModel.cleanup()
    }

    @objc private func screenConfigurationChanged() {
        setExpanded(lastExpandedState, forceReposition: true)
    }

    func handleExpansionChange(_ expanded: Bool) {
        setExpanded(expanded)
    }

    private func setExpanded(_ expanded: Bool, forceReposition: Bool = false) {
        guard let window else { return }
        guard forceReposition || lastExpandedState != expanded else { return }
        lastExpandedState = expanded

        let targetWidth = expanded ? expandedWidth : collapsedWidth
        let screenFrame = NSScreen.screen(for: presetSettings.displayTarget)?.frame ?? .zero
        let yPosition = screenFrame.maxY - notchHeight
        let xPosition = screenFrame.midX - (targetWidth / 2)
        let newFrame = NSRect(x: xPosition, y: yPosition, width: targetWidth, height: notchHeight)

        DispatchQueue.main.async {
            window.setFrame(newFrame, display: true, animate: false)
        }
    }
}

// MARK: - NotchWindow

internal class NotchWindow: NSPanel {
    init(width: CGFloat, height: CGFloat, displayTarget: DisplayTarget) {
        let screenFrame = NSScreen.screen(for: displayTarget)?.frame ?? .zero
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
