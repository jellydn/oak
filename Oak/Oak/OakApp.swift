import AppKit
import SwiftUI

@main
internal struct OakApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var presetSettings = PresetSettingsStore.shared
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var launchAtLoginService = LaunchAtLoginService.shared

    var body: some Scene {
        Settings {
            if let sparkleUpdater = appDelegate.sparkleUpdater {
                SettingsMenuView(
                    presetSettings: presetSettings,
                    notificationService: notificationService,
                    sparkleUpdater: sparkleUpdater,
                    launchAtLoginService: launchAtLoginService
                )
                .frame(width: 320)
                .padding(8)
            } else {
                SettingsMenuView(
                    presetSettings: presetSettings,
                    notificationService: notificationService,
                    sparkleUpdater: SparkleUpdater.shared,
                    launchAtLoginService: launchAtLoginService
                )
                .frame(width: 320)
                .padding(8)
            }
        }
    }
}

@MainActor
internal class AppDelegate: NSObject, NSApplicationDelegate {
    var notchWindowController: NotchWindowController?
    var sparkleUpdater: SparkleUpdater?
    private let notificationService = NotificationService.shared
    private let launchAtLoginService = LaunchAtLoginService.shared
    private let presetSettings = PresetSettingsStore.shared
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

        // Initialize Sparkle updater to enable automatic update checks on launch
        sparkleUpdater = SparkleUpdater.shared

        // Sync launch at login preference with actual state
        launchAtLoginService.refreshStatus()
        if launchAtLoginService.isEnabled != presetSettings.launchAtLogin {
            presetSettings.setLaunchAtLogin(launchAtLoginService.isEnabled)
        }

        // Keep status in sync at launch; permission requests are user-initiated from Settings.
        Task { @MainActor in
            await notificationService.refreshAuthorizationStatus()
        }
    }

    func applicationWillTerminate(_: Notification) {
        notchWindowController?.cleanup()
    }

    func applicationDidBecomeActive(_: Notification) {
        Task { @MainActor in
            await notificationService.refreshAuthorizationStatus()
        }
    }

    deinit {
        let windowController = notchWindowController
        Task { @MainActor in
            windowController?.cleanup()
        }
    }
}
