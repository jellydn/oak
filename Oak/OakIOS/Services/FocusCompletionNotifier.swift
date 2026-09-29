import Foundation
import UserNotifications

@MainActor
internal protocol FocusCompletionNotifying {
    func scheduleCompletion(for kind: FocusIntervalKind, at date: Date, intervalID: UUID)
    func cancelPendingCompletion()
}

@MainActor
internal protocol FocusNotificationCentering {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

@MainActor
internal final class SystemFocusNotificationCenter: FocusNotificationCentering {
    private let center: UNUserNotificationCenter

    internal init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    internal func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    internal func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    internal func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }

    internal func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

@MainActor
internal final class FocusCompletionNotifier: FocusCompletionNotifying {
    private let center: any FocusNotificationCentering
    private var activeRequestIdentifier: String?
    private var schedulingTask: Task<Void, Never>?

    internal init(center: (any FocusNotificationCentering)? = nil) {
        self.center = center ?? SystemFocusNotificationCenter()
    }

    internal func scheduleCompletion(for kind: FocusIntervalKind, at date: Date, intervalID: UUID) {
        let previousTask = schedulingTask
        previousTask?.cancel()
        if let activeRequestIdentifier {
            center.removePendingNotificationRequests(withIdentifiers: [activeRequestIdentifier])
        }
        let center = center
        let requestIdentifier = "oak-ios-session-completion-\(intervalID.uuidString)"
        activeRequestIdentifier = requestIdentifier
        schedulingTask = Task { [weak self] in
            await previousTask?.value
            guard !Task.isCancelled else { return }

            let authorizationStatus = await center.authorizationStatus()
            guard !Task.isCancelled else { return }
            if authorizationStatus == .notDetermined {
                _ = try? await center.requestAuthorization()
            }
            guard !Task.isCancelled else { return }

            let content = UNMutableNotificationContent()
            content.title = kind.isFocus ? "Focus complete" : "Break complete"
            content.body = kind.isFocus ? "Take a well-earned break." : "Ready for another Focus Session?"
            content.sound = .default
            let delay = max(1, date.timeIntervalSinceNow)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            let request = UNNotificationRequest(
                identifier: requestIdentifier,
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
            guard !Task.isCancelled, self?.activeRequestIdentifier == requestIdentifier else {
                center.removePendingNotificationRequests(withIdentifiers: [requestIdentifier])
                return
            }
            self?.schedulingTask = nil
        }
    }

    internal func cancelPendingCompletion() {
        schedulingTask?.cancel()
        if let activeRequestIdentifier {
            center.removePendingNotificationRequests(withIdentifiers: [activeRequestIdentifier])
        }
        activeRequestIdentifier = nil
    }
}
