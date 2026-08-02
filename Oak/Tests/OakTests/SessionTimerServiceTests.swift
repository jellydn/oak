import Foundation
import XCTest
@testable import Oak

@MainActor
internal final class SessionTimerServiceTests: XCTestCase {
    func testSessionTimerFiresInCommonRunLoopModes() {
        let service = SessionTimerService()
        service.start(seconds: 2)

        let deadline = Date().addingTimeInterval(1.2)
        while Date() < deadline {
            _ = RunLoop.main.run(mode: .eventTracking, before: deadline)
        }

        XCTAssertLessThan(service.remainingSeconds, 2, "Session timer should tick in common run-loop modes")
        service.stop()
    }

    func testAutoStartCountdownUsesElapsedTime() {
        let service = SessionTimerService()
        service.startAutoStartCountdown()

        RunLoop.main.run(until: Date().addingTimeInterval(1.2))

        XCTAssertLessThanOrEqual(service.autoStartCountdown, 9)
        XCTAssertGreaterThan(service.autoStartCountdown, 0)
        service.cancelAutoStartCountdown()
    }

    func testPauseAndResumePreserveSubsecondRemainingInterval() {
        let service = SessionTimerService()
        service.start(seconds: 3)
        RunLoop.main.run(until: Date().addingTimeInterval(1.8))
        service.pause()

        var didFinish = false
        let cancellable = service.timerFinished.sink {
            didFinish = true
        }

        service.resume()
        RunLoop.main.run(until: Date().addingTimeInterval(1.5))

        XCTAssertTrue(didFinish, "The timer should finish after the preserved fractional remainder elapses")
        cancellable.cancel()
        service.stop()
    }
}
