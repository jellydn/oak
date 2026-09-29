import AppKit
import Foundation
import os
import UserNotifications

@MainActor
internal protocol SessionCompletionNotifying {
    func sendSessionCompletionNotification(isWorkSession: Bool)
}

@MainActor
internal class NotificationService: ObservableObject, SessionCompletionNotifying {
    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let logger = Logger(subsystem: "com.productsway.oak.app", category: "NotificationService")
    private let applicationActivator: @MainActor () async -> Bool
    private let authorizationRequester: @MainActor () async throws -> Bool
    private let authorizationStatusProvider: @MainActor () async -> UNAuthorizationStatus

    internal init(
        applicationActivator: @escaping @MainActor () async -> Bool = {
            await NotificationService.activateApplication()
        },
        authorizationRequester: @escaping @MainActor () async throws -> Bool = {
            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        },
        authorizationStatusProvider: @escaping @MainActor () async -> UNAuthorizationStatus = {
            await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        }
    ) {
        self.applicationActivator = applicationActivator
        self.authorizationRequester = authorizationRequester
        self.authorizationStatusProvider = authorizationStatusProvider

        Task {
            await refreshAuthorizationStatus()
        }
    }

    internal func requestAuthorization() async {
        guard await applicationActivator() else {
            logger.error("Failed to activate Oak before requesting notification permission")
            await refreshAuthorizationStatus()
            return
        }

        do {
            _ = try await authorizationRequester()
            await refreshAuthorizationStatus()
        } catch {
            if let notificationError = error as? UNError, notificationError.code == .notificationsNotAllowed {
                logger.info("Notification permission is unavailable for this app configuration.")
            } else {
                logger.error("Failed to request notification permission: \(error.localizedDescription)")
            }
            await refreshAuthorizationStatus()
        }
    }

    internal func refreshAuthorizationStatus() async {
        let status = await authorizationStatusProvider()
        authorizationStatus = status
        isAuthorized = isGrantedStatus(status)
    }

    func openNotificationSettings() {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.productsway.oak.app"
        let candidateURLs = [
            "x-apple.systempreferences:com.apple.Notifications-Settings.extension?\(bundleIdentifier)",
            "x-apple.systempreferences:com.apple.Notifications-Settings.extension",
            "x-apple.systempreferences:com.apple.preference.notifications"
        ]

        for candidate in candidateURLs {
            guard let url = URL(string: candidate) else { continue }
            if NSWorkspace.shared.open(url) {
                return
            }
        }

        logger.error("Failed to open Notification settings")
    }

    func sendSessionCompletionNotification(isWorkSession: Bool) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        if isWorkSession {
            content.title = "Focus Session Complete!"
            content.body = "Great work! Time for a break."
            content.sound = .default
        } else {
            content.title = "Break Complete!"
            content.body = "Ready to focus again?"
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                Task { @MainActor in
                    self.logger.error("Failed to send notification: \(error.localizedDescription)")
                }
            }
        }
    }

    private func isGrantedStatus(_ status: UNAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied, .notDetermined:
            return false
        @unknown default:
            return false
        }
    }

    private static func activateApplication() async -> Bool {
        guard !NSApp.isActive else { return true }

        NSApp.activate(ignoringOtherApps: true)
        let deadline = Date().addingTimeInterval(1)

        while !NSApp.isActive, Date() < deadline {
            do {
                try await Task.sleep(nanoseconds: 10_000_000)
            } catch {
                return false
            }
        }

        return NSApp.isActive
    }
}
