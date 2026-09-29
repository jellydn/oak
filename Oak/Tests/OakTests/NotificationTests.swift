import Foundation
import UserNotifications
import XCTest
@testable import Oak

@MainActor
private final class NotificationTestGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var isOpen = false

    func wait() async {
        guard !isOpen else { return }

        await withCheckedContinuation { continuation in
            if isOpen {
                continuation.resume()
            } else {
                self.continuation = continuation
            }
        }
    }

    func open() {
        guard !isOpen else { return }

        isOpen = true
        continuation?.resume()
        continuation = nil
    }
}

@MainActor
internal final class NotificationTests: XCTestCase {
    var notificationService: NotificationService!

    override func setUp() async throws {
        notificationService = NotificationService()
    }

    override func tearDown() async throws {
        notificationService = nil
    }

    func testNotificationServiceInitialization() {
        XCTAssertNotNil(notificationService, "NotificationService should be initialized")
    }

    func testNotificationServiceCanSendWorkSessionNotification() {
        // Test that method doesn't crash when called
        notificationService.sendSessionCompletionNotification(isWorkSession: true)
        XCTAssertTrue(true, "Work session notification sent without crash")
    }

    func testNotificationServiceCanSendBreakSessionNotification() {
        // Test that method doesn't crash when called
        notificationService.sendSessionCompletionNotification(isWorkSession: false)
        XCTAssertTrue(true, "Break session notification sent without crash")
    }

    func testAuthorizationRequestActivatesAppBeforeShowingPromptAndRefreshesStatus() async {
        var events: [String] = []
        var authorizationStatus: UNAuthorizationStatus = .notDetermined
        let activationGate = NotificationTestGate()
        let authorizationGate = NotificationTestGate()

        notificationService = NotificationService(
            applicationActivator: {
                events.append("activationStarted")
                await activationGate.wait()
                events.append("activationCompleted")
                return true
            },
            authorizationRequester: {
                events.append("authorizationRequested")
                await authorizationGate.wait()
                return true
            },
            authorizationStatusProvider: {
                events.append("statusRefreshed")
                return authorizationStatus
            }
        )

        guard await waitUntil({ events == ["statusRefreshed"] }) else {
            XCTFail("Initial authorization status did not refresh")
            return
        }
        events.removeAll()

        let requestTask = Task {
            await notificationService.requestAuthorization()
        }

        guard await waitUntil({ events.contains("activationStarted") }) else {
            activationGate.open()
            authorizationGate.open()
            await requestTask.value
            XCTFail("Authorization flow did not start activation")
            return
        }
        XCTAssertEqual(events, ["activationStarted"])

        activationGate.open()
        guard await waitUntil({ events.contains("authorizationRequested") }) else {
            authorizationGate.open()
            await requestTask.value
            XCTFail("Authorization request did not start after activation")
            return
        }
        XCTAssertEqual(events, ["activationStarted", "activationCompleted", "authorizationRequested"])

        authorizationStatus = .authorized
        authorizationGate.open()
        await requestTask.value

        XCTAssertEqual(
            events,
            ["activationStarted", "activationCompleted", "authorizationRequested", "statusRefreshed"]
        )
        XCTAssertEqual(notificationService.authorizationStatus, .authorized)
        XCTAssertTrue(notificationService.isAuthorized)
    }

    private func waitUntil(_ condition: () -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(1)

        while !condition(), Date() < deadline {
            await Task.yield()
        }

        return condition()
    }
}
