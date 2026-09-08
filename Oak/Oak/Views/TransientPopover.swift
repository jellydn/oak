import AppKit
import SwiftUI

internal struct ClickOutsideModifier: ViewModifier {
    let isDismissalSuppressed: Binding<Bool>
    let action: () -> Void
    @State private var monitor: Any?
    @State private var localMonitor: Any?
    @State private var popoverWindow: NSWindow?

    internal init(
        isDismissalSuppressed: Binding<Bool> = .constant(false),
        action: @escaping () -> Void
    ) {
        self.isDismissalSuppressed = isDismissalSuppressed
        self.action = action
    }

    internal var isDismissalEnabled: Bool {
        !isDismissalSuppressed.wrappedValue
    }

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
                    guard isDismissalEnabled, let popoverWindow else { return }

                    if !popoverWindow.frame.contains(NSEvent.mouseLocation) {
                        DispatchQueue.main.async {
                            action()
                        }
                    }
                }

                let localEventMonitor: (NSEvent) -> NSEvent = { [popoverWindow] event in
                    guard isDismissalEnabled, let popoverWindow else { return event }

                    if event.window != popoverWindow {
                        DispatchQueue.main.async {
                            action()
                        }
                    }
                    return event
                }
                localMonitor = NSEvent.addLocalMonitorForEvents(
                    matching: [.leftMouseDown, .rightMouseDown],
                    handler: localEventMonitor
                )
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
    func dismissOnClickOutside(
        isDismissalSuppressed: Binding<Bool> = .constant(false),
        action: @escaping () -> Void
    ) -> some View {
        modifier(ClickOutsideModifier(isDismissalSuppressed: isDismissalSuppressed, action: action))
    }
}
