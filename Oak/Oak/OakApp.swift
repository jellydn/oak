import SwiftUI
import AppKit

@main
struct OakApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var notchWindowController: NotchWindowController?
    var updateChecker: UpdateChecking = UpdateChecker()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        notchWindowController = NotchWindowController()
        notchWindowController?.window?.orderFrontRegardless()
        updateChecker.checkForUpdatesOnLaunch()
    }

    func applicationWillTerminate(_ notification: Notification) {
        notchWindowController?.cleanup()
    }
}
