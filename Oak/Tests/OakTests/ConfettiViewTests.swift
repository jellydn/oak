import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class ConfettiViewTests: XCTestCase {
    func testConfettiViewInitialization() {
        let view = ConfettiView()
        XCTAssertNotNil(view)
    }

    func testConfettiViewWithCustomCount() {
        let view = ConfettiView(count: 50)
        XCTAssertNotNil(view)
    }

    func testAnimationDurationIsPositive() {
        XCTAssertGreaterThan(ConfettiView.animationDuration, 0, "Animation duration must be positive")
    }

    func testDefaultCountIsReasonable() {
        let view = ConfettiView()
        XCTAssertEqual(view.count, 30, "Default confetti count should be 30")
    }

    func testCustomCountPreservesValue() {
        let view = ConfettiView(count: 100)
        XCTAssertEqual(view.count, 100)
    }

    func testAnimationDurationMatchesDesignConstant() {
        XCTAssertEqual(ConfettiView.animationDuration, 1.2, accuracy: 0.01)
    }

    func testZeroCountCreatesViewWithoutCrash() {
        let view = ConfettiView(count: 0)
        XCTAssertNotNil(view, "ConfettiView with zero count should not crash")
    }

    func testLargeCountCreatesViewWithoutCrash() {
        let view = ConfettiView(count: 1000)
        XCTAssertNotNil(view, "ConfettiView with large count should not crash")
    }
}
