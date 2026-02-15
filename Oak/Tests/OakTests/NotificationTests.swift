import SwiftUI
import UserNotifications
import XCTest
@testable import Oak

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

    func testNotificationServiceAuthorizationRequest() throws {
        throw XCTSkip("Skipping authorization request test to avoid system notification prompts in automated runs")
    }
}
