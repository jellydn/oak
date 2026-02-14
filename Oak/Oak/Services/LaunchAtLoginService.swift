import Foundation
import ServiceManagement

@MainActor
internal final class LaunchAtLoginService: ObservableObject {
    static let shared = LaunchAtLoginService()

    @Published private(set) var isEnabled: Bool

    private let service = SMAppService.mainApp

    private init() {
        isEnabled = service.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        guard isEnabled != enabled else { return }

        do {
            if enabled {
                if service.status == .enabled {
                    isEnabled = true
                } else {
                    try service.register()
                    isEnabled = true
                }
            } else {
                try service.unregister()
                isEnabled = false
            }
        } catch {
            // If registration fails, log the error but don't crash
            // The user might not have the necessary permissions
            NSLog("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
        }
    }

    func refreshStatus() {
        let newStatus = service.status == .enabled
        if isEnabled != newStatus {
            isEnabled = newStatus
        }
    }
}
