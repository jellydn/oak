import AppKit
import SwiftUI

@main
internal struct OakApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var presetSettings = PresetSettingsStore.shared

    var body: some Scene {
        Settings {
            SettingsMenuView(presetSettings: presetSettings)
                .frame(width: 320)
                .padding(8)
        }
    }
}

internal class AppDelegate: NSObject, NSApplicationDelegate {
    var notchWindowController: NotchWindowController?
    var updateChecker: UpdateChecking = UpdateChecker()
    private var isRunningTests: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCTestConfigurationFilePath"] != nil || environment["XCTestBundlePath"] != nil
    }

    func applicationDidFinishLaunching(_: Notification) {
        if isRunningTests {
            return
        }

        NSApp.setActivationPolicy(.accessory)

        notchWindowController = NotchWindowController()
        notchWindowController?.window?.orderFrontRegardless()
        updateChecker.checkForUpdatesOnLaunch()
    }

    func applicationWillTerminate(_: Notification) {
        notchWindowController?.cleanup()
    }
}
