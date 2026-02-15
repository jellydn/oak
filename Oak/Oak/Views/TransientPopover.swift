import AppKit
import SwiftUI

internal struct ClickOutsideModifier: ViewModifier {
    let action: () -> Void
    @State private var monitor: Any?
    @State private var localMonitor: Any?

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard monitor == nil, localMonitor == nil else { return }
                monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
                    action()
                }
                localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
                    action()
                    return event
                }
            }
            .onDisappear {
                if let monitor {
                    NSEvent.removeMonitor(monitor)
                    self.monitor = nil
                }
                if let localMonitor {
                    NSEvent.removeMonitor(localMonitor)
                    self.localMonitor = nil
                }
            }
    }
}

internal extension View {
    func dismissOnClickOutside(action: @escaping () -> Void) -> some View {
        modifier(ClickOutsideModifier(action: action))
    }
}
