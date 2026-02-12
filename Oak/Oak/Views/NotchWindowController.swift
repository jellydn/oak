import SwiftUI
import AppKit

class NotchWindowController: NSWindowController {
    private let collapsedWidth: CGFloat = 144
    private let expandedWidth: CGFloat = 372
    private let notchHeight: CGFloat = 33
    private var lastExpandedState: Bool?

    convenience init() {
        let window = NotchWindow(width: 144, height: 33)
        self.init(window: window)

        let contentView = NotchCompanionView { [weak self] expanded in
            self?.setExpanded(expanded)
        }
        window.contentView = NSHostingView(rootView: contentView)

        window.orderFrontRegardless()
    }

    func cleanup() {
        (window?.contentView as? NSHostingView<NotchCompanionView>)?.rootView.viewModel.cleanup()
    }

    private func setExpanded(_ expanded: Bool) {
        guard let window else { return }
        guard lastExpandedState != expanded else { return }
        lastExpandedState = expanded

        let targetWidth = expanded ? expandedWidth : collapsedWidth
        let screenFrame = NSScreen.main?.frame ?? .zero
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
        let screenFrame = NSScreen.main?.frame ?? .zero
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
}
