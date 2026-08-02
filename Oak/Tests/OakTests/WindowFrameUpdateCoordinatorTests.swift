import XCTest
@testable import Oak

@MainActor
internal final class WindowFrameUpdateCoordinatorTests: XCTestCase {
    func testCoalescesRequestsAndKeepsLatestState() {
        let coordinator = WindowFrameUpdateCoordinator()
        var applied: [WindowFrameUpdateRequest] = []

        coordinator.request(expanded: false) { applied.append($0) }
        coordinator.request(expanded: true) { applied.append($0) }

        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        XCTAssertEqual(applied, [WindowFrameUpdateRequest(expanded: true, forceReposition: false, targetOverride: nil)])
    }

    func testForceRepositionIsPreservedAcrossCoalescedRequests() {
        let coordinator = WindowFrameUpdateCoordinator()
        var applied: WindowFrameUpdateRequest?

        coordinator.request(expanded: false, forceReposition: true) { applied = $0 }
        coordinator.request(expanded: true) { applied = $0 }

        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        XCTAssertEqual(applied?.expanded, true)
        XCTAssertEqual(applied?.forceReposition, true)
    }

    func testLatestTargetOverrideWins() {
        let coordinator = WindowFrameUpdateCoordinator()
        var applied: WindowFrameUpdateRequest?

        coordinator.request(expanded: false, targetOverride: .mainDisplay) { applied = $0 }
        coordinator.request(expanded: false, targetOverride: .notchedDisplay) { applied = $0 }

        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        XCTAssertEqual(applied?.targetOverride, .notchedDisplay)
    }
}
