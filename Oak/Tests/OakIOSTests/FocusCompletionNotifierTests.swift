import UserNotifications
import XCTest
@testable import OakIOS

@MainActor
internal final class FocusCompletionNotifierTests: XCTestCase {
    func testCancelWhileAuthorizationIsPendingDoesNotAddNotification() async {
        let center = SuspendedFocusNotificationCenter()
        let notifier = FocusCompletionNotifier(center: center)

        notifier.scheduleCompletion(
            for: .focus,
            at: Date().addingTimeInterval(60),
            intervalID: UUID()
        )
        await Task.yield()
        notifier.cancelPendingCompletion()
        center.finishAuthorizationStatus()
        await Task.yield()

        XCTAssertTrue(center.addedRequests.isEmpty)
    }

    func testIntervalIdentifierIsStableAcrossNotifierInstances() async {
        let center = CapturingFocusNotificationCenter()
        let intervalID = UUID()
        let firstNotifier = FocusCompletionNotifier(center: center)

        firstNotifier.scheduleCompletion(
            for: .focus,
            at: Date().addingTimeInterval(60),
            intervalID: intervalID
        )
        let didAddFirstRequest = await center.waitForRequestCount(1)
        XCTAssertTrue(didAddFirstRequest)
        guard didAddFirstRequest else { return }

        let restoredNotifier = FocusCompletionNotifier(center: center)
        restoredNotifier.scheduleCompletion(
            for: .focus,
            at: Date().addingTimeInterval(60),
            intervalID: intervalID
        )
        let didAddRestoredRequest = await center.waitForRequestCount(2)
        XCTAssertTrue(didAddRestoredRequest)
        guard didAddRestoredRequest else { return }

        XCTAssertEqual(center.addedRequests[0].identifier, center.addedRequests[1].identifier)
    }

    func testRescheduleWaitsForCancelledAddBeforeRegisteringReplacement() async throws {
        let center = SuspendedAddFocusNotificationCenter()
        let notifier = FocusCompletionNotifier(center: center)
        let intervalID = UUID()

        notifier.scheduleCompletion(
            for: .focus,
            at: Date().addingTimeInterval(30),
            intervalID: intervalID
        )
        let didStartFirstAdd = await center.waitForPendingAddCount(1)
        XCTAssertTrue(didStartFirstAdd)
        guard didStartFirstAdd else { return }

        notifier.cancelPendingCompletion()
        notifier.scheduleCompletion(
            for: .focus,
            at: Date().addingTimeInterval(60),
            intervalID: intervalID
        )
        await Task.yield()
        XCTAssertEqual(center.pendingAddCount, 1)

        center.finishNextAdd()
        let didStartReplacementAdd = await center.waitForPendingAddCount(1)
        XCTAssertTrue(didStartReplacementAdd)
        guard didStartReplacementAdd else { return }
        center.finishNextAdd()
        let didRegisterReplacement = await center.waitForRegisteredRequest()
        XCTAssertTrue(didRegisterReplacement)
        guard didRegisterReplacement else { return }

        XCTAssertEqual(center.registeredRequests.count, 1)
        let request = try XCTUnwrap(center.registeredRequests.values.first)
        let trigger = try XCTUnwrap(request.trigger as? UNTimeIntervalNotificationTrigger)
        XCTAssertGreaterThan(trigger.timeInterval, 30)

        notifier.cancelPendingCompletion()
        XCTAssertTrue(center.registeredRequests.isEmpty)
    }
}

@MainActor
private final class CapturingFocusNotificationCenter: FocusNotificationCentering {
    private(set) var addedRequests: [UNNotificationRequest] = []

    func authorizationStatus() async -> UNAuthorizationStatus {
        .authorized
    }

    func requestAuthorization() async throws -> Bool {
        true
    }

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers _: [String]) {}

    func waitForRequestCount(_ count: Int) async -> Bool {
        for _ in 0 ..< 100 where addedRequests.count < count {
            await Task.yield()
        }
        return addedRequests.count >= count
    }
}

@MainActor
private final class SuspendedAddFocusNotificationCenter: FocusNotificationCentering {
    private struct PendingAdd {
        let request: UNNotificationRequest
        let continuation: CheckedContinuation<Void, Error>
    }

    private var pendingAdds: [PendingAdd] = []
    private(set) var registeredRequests: [String: UNNotificationRequest] = [:]

    var pendingAddCount: Int {
        pendingAdds.count
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        .authorized
    }

    func requestAuthorization() async throws -> Bool {
        true
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { continuation in
            pendingAdds.append(PendingAdd(request: request, continuation: continuation))
        }
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        for identifier in identifiers {
            registeredRequests.removeValue(forKey: identifier)
        }
    }

    func finishNextAdd() {
        let pendingAdd = pendingAdds.removeFirst()
        registeredRequests[pendingAdd.request.identifier] = pendingAdd.request
        pendingAdd.continuation.resume()
    }

    func waitForPendingAddCount(_ count: Int) async -> Bool {
        for _ in 0 ..< 100 where pendingAdds.count < count {
            await Task.yield()
        }
        return pendingAdds.count >= count
    }

    func waitForRegisteredRequest() async -> Bool {
        for _ in 0 ..< 100 where registeredRequests.isEmpty {
            await Task.yield()
        }
        return !registeredRequests.isEmpty
    }
}

@MainActor
private final class SuspendedFocusNotificationCenter: FocusNotificationCentering {
    private var authorizationContinuation: CheckedContinuation<UNAuthorizationStatus, Never>?
    private(set) var addedRequests: [UNNotificationRequest] = []

    func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            authorizationContinuation = continuation
        }
    }

    func requestAuthorization() async throws -> Bool {
        true
    }

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers _: [String]) {}

    func finishAuthorizationStatus() {
        authorizationContinuation?.resume(returning: .authorized)
        authorizationContinuation = nil
    }
}
