import SwiftUI
import AppKit

// MARK: - Screen Detection Helper

extension NSScreen {
    static func screenWithNotch() -> NSScreen? {
        // Prefer main screen if it has a notch (macOS 12+)
        if let mainScreen = NSScreen.main {
            if #available(macOS 12.0, *) {
                if mainScreen.auxiliaryTopLeftArea != nil {
                    return mainScreen
                }
            }
        }
        
        // Check other screens for notch
        for screen in NSScreen.screens {
            if #available(macOS 12.0, *) {
                if screen.auxiliaryTopLeftArea != nil {
                    return screen
                }
            }
        }
        
        return NSScreen.main ?? NSScreen.screens.first
    }
}

// MARK: - NotchWindowController

@MainActor
class NotchWindowController: NSWindowController {
    private let collapsedWidth: CGFloat = 144
    private let expandedWidth: CGFloat = 372
    private let notchHeight: CGFloat = 33
    private var lastExpandedState: Bool = false
    private let viewModel: FocusSessionViewModel

    convenience init() {
        self.init(presetSettings: nil)
    }

    init(presetSettings: PresetSettingsStore?) {
        let settings = presetSettings ?? PresetSettingsStore.shared
        self.viewModel = FocusSessionViewModel(presetSettings: settings)
        
        let window = NotchWindow(width: 144, height: 33)
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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func cleanup() {
        viewModel.cleanup()
    }

    @objc private func screenConfigurationChanged() {
        setExpanded(lastExpandedState)
    }

    func handleExpansionChange(_ expanded: Bool) {
        setExpanded(expanded)
    }

    private func setExpanded(_ expanded: Bool) {
        guard let window else { return }
        guard lastExpandedState != expanded else { return }
        lastExpandedState = expanded

        let targetWidth = expanded ? expandedWidth : collapsedWidth
        let screen = NSScreen.screenWithNotch()
        let screenFrame = screen?.frame ?? .zero
        let yPosition = screenFrame.height - notchHeight
        let xPosition = (screenFrame.width - targetWidth) / 2
        let newFrame = NSRect(x: xPosition, y: yPosition, width: targetWidth, height: notchHeight)

        DispatchQueue.main.async {
            window.setFrame(newFrame, display: true, animate: false)
        }
    }
}

// MARK: - NotchWindow

class NotchWindow: NSPanel {
    init(width: CGFloat, height: CGFloat) {
        let screen = NSScreen.screenWithNotch()
        let screenFrame = screen?.frame ?? .zero
        let xPosition = (screenFrame.width - width) / 2

        super.init(
            contentRect: NSRect(x: xPosition, y: screenFrame.height - height, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
    }

    override func rightMouseDown(with event: NSEvent) {
        super.rightMouseDown(with: event)
    }
}
