import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class ConfettiViewTests: XCTestCase {
    func testConfettiViewInitialization() {
        let confettiView = ConfettiView()
        XCTAssertNotNil(confettiView, "ConfettiView should be initialized")
    }
    
    func testConfettiViewWithCustomCount() {
        let confettiView = ConfettiView(count: 50)
        XCTAssertNotNil(confettiView, "ConfettiView with custom count should be initialized")
    }
}
