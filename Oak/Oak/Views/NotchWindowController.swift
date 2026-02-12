import SwiftUI
import AppKit

class NotchWindowController: NSWindowController {
    private let viewModel = FocusSessionViewModel()
    
    convenience init() {
        let window = NotchWindow()
        self.init(window: window)
        
        let contentView = NotchCompanionView()
        window.contentView = NSHostingView(rootView: contentView)
        
        window.makeKeyAndOrderFront(nil)
    }
    
    func cleanup() {
        (window?.contentView as? NSHostingView<NotchCompanionView>)?.rootView.viewModel.cleanup()
    }
}

class NotchWindow: NSWindow {
    init() {
        let screenFrame = NSScreen.main?.frame ?? .zero
        let notchWidth: CGFloat = 300
        let notchHeight: CGFloat = 80
        let xPosition = (screenFrame.width - notchWidth) / 2
        
        super.init(
            contentRect: NSRect(x: xPosition, y: screenFrame.height - notchHeight, width: notchWidth, height: notchHeight),
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
