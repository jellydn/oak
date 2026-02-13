import Foundation
import UserNotifications

@MainActor
internal class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized: Bool = false
    
    init() {
        checkAuthorizationStatus()
    }
    
    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            isAuthorized = granted
        } catch {
            isAuthorized = false
        }
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
                    print("Error sending notification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }
}
