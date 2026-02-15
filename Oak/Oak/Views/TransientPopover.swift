import AppKit
import SwiftUI

internal struct ClickOutsideModifier: ViewModifier {
    let action: () -> Void
    @State private var monitor: Any?

    func body(content: Content) -> some View {
        content
            .onAppear {
                monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
                    action()
                }
            }
            .onDisappear {
                if let monitor {
                    NSEvent.removeMonitor(monitor)
                }
            }
    }
}

internal extension View {
    func dismissOnClickOutside(action: @escaping () -> Void) -> some View {
        modifier(ClickOutsideModifier(action: action))
    }
}
