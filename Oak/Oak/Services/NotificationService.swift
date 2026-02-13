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
    static let shared = NotificationService()

    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let logger = Logger(subsystem: "com.productsway.oak.app", category: "NotificationService")

    private init() {
        Task {
            await refreshAuthorizationStatus()
        }
    }

    func requestAuthorization() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
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

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = isGrantedStatus(settings.authorizationStatus)
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
}
