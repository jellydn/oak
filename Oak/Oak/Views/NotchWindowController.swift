import SwiftUI
import AppKit

class NotchWindowController: NSWindowController {
    private let collapsedWidth: CGFloat = 144
    private let expandedWidth: CGFloat = 372
    private let notchHeight: CGFloat = 33
    private var lastExpandedState: Bool?
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
        
        // Observe display configuration changes
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
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func screenConfigurationChanged() {
        // Recalculate window position when display configuration changes
        guard let currentExpanded = lastExpandedState else { return }
        setExpanded(currentExpanded)
    }

    private func findScreenWithNotch() -> NSScreen? {
        // Try to find a screen with auxiliaryTopLeftArea (indicates notch)
        // This property is available on macOS 12+ and returns non-nil for screens with notch
        for screen in NSScreen.screens {
            if #available(macOS 12.0, *) {
                if screen.auxiliaryTopLeftArea != nil {
                    return screen
                }
            }
        }
        
        // Fallback: look for built-in display by checking if it's the main screen
        // The built-in display is typically the one with the highest pixel density
        // and is usually the main screen when it's the only display
        if let mainScreen = NSScreen.main {
            return mainScreen
        }
        
        // Last resort: return the first screen
        return NSScreen.screens.first
    }

    func handleExpansionChange(_ expanded: Bool) {
        setExpanded(expanded)
    }

    private func setExpanded(_ expanded: Bool) {
        guard let window else { return }
        guard lastExpandedState != expanded else { return }
        lastExpandedState = expanded

        let targetWidth = expanded ? expandedWidth : collapsedWidth
        let screen = findScreenWithNotch()
        let screenFrame = screen?.frame ?? .zero
        let yPosition = screenFrame.height - notchHeight
        let xPosition = (screenFrame.width - targetWidth) / 2
        let newFrame = NSRect(x: xPosition, y: yPosition, width: targetWidth, height: notchHeight)

        // Avoid recursive layout warnings by resizing outside the current update cycle.
        DispatchQueue.main.async {
            window.setFrame(newFrame, display: true, animate: false)
        }
    }
}

class NotchWindow: NSPanel {
    init(width: CGFloat, height: CGFloat) {
        let screen = NotchWindow.findScreenWithNotch()
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

    private static func findScreenWithNotch() -> NSScreen? {
        // Try to find a screen with auxiliaryTopLeftArea (indicates notch)
        for screen in NSScreen.screens {
            if #available(macOS 12.0, *) {
                if screen.auxiliaryTopLeftArea != nil {
                    return screen
                }
            }
        }
        
        // Fallback: return main screen or first screen
        return NSScreen.main ?? NSScreen.screens.first
    }

    override func rightMouseDown(with event: NSEvent) {
        super.rightMouseDown(with: event)
    }
}
