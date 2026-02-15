import AppKit
import SwiftUI

internal struct ClickOutsideModifier: ViewModifier {
    let action: () -> Void
    @State private var monitor: Any?
    @State private var localMonitor: Any?
    @State private var popoverWindow: NSWindow?

    private struct WindowAccessor: NSViewRepresentable {
        @Binding var window: NSWindow?

        func makeNSView(context _: Context) -> NSView {
            let view = NSView()
            DispatchQueue.main.async {
                window = view.window
            }
            return view
        }

        func updateNSView(_ nsView: NSView, context _: Context) {
            DispatchQueue.main.async {
                window = nsView.window
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .background(WindowAccessor(window: $popoverWindow))
            .onAppear {
                guard monitor == nil, localMonitor == nil else { return }

                monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
                    guard let popoverWindow else { return }

                    if !popoverWindow.frame.contains(NSEvent.mouseLocation) {
                        DispatchQueue.main.async {
                            action()
                        }
                    }
                }

                localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
                    guard let popoverWindow else { return event }

                    if !popoverWindow.frame.contains(NSEvent.mouseLocation) {
                        DispatchQueue.main.async {
                            action()
                        }
                    }
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
                popoverWindow = nil
            }
    }
}

internal extension View {
    func dismissOnClickOutside(action: @escaping () -> Void) -> some View {
        modifier(ClickOutsideModifier(action: action))
    }
}
