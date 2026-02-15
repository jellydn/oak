import AppKit
import SwiftUI

@main
internal struct OakApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsMenuView(
                presetSettings: appDelegate.presetSettings ?? PresetSettingsStore(),
                notificationService: appDelegate.notificationService ?? NotificationService(),
                sparkleUpdater: appDelegate.sparkleUpdater ?? SparkleUpdater()
            )
            .frame(width: 420)
            .padding(8)
        }
    }
}

@MainActor
internal class AppDelegate: NSObject, NSApplicationDelegate {
    var notchWindowController: NotchWindowController?
    var sparkleUpdater: SparkleUpdater?
    var notificationService: NotificationService?
    var presetSettings: PresetSettingsStore?
    private var isRunningTests: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCTestConfigurationFilePath"] != nil || environment["XCTestBundlePath"] != nil
    }

    func applicationDidFinishLaunching(_: Notification) {
        if isRunningTests {
            return
        }

        NSApp.setActivationPolicy(.accessory)

        // Create shared instances
        presetSettings = PresetSettingsStore()
        notificationService = NotificationService()
        sparkleUpdater = SparkleUpdater()

        // Pass dependencies to NotchWindowController
        notchWindowController = NotchWindowController(
            presetSettings: presetSettings!,
            notificationService: notificationService!,
            sparkleUpdater: sparkleUpdater!
        )
        notchWindowController?.window?.orderFrontRegardless()

        // Keep status in sync at launch; permission requests are user-initiated from Settings.
        Task { @MainActor in
            await notificationService?.refreshAuthorizationStatus()
        }
    }

    func applicationWillTerminate(_: Notification) {
        notchWindowController?.cleanup()
    }

    func applicationDidBecomeActive(_: Notification) {
        Task { @MainActor in
            await notificationService?.refreshAuthorizationStatus()
        }
    }
}
