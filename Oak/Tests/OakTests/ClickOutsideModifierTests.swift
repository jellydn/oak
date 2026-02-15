import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class ClickOutsideModifierTests: XCTestCase {
    func testModifierInitialization() {
        let modifier = ClickOutsideModifier {}
        XCTAssertNotNil(modifier, "ClickOutsideModifier should be initialized")
    }

    func testViewExtensionExists() {
        let view = Text("Test")
        let modifiedView = view.dismissOnClickOutside {}
        XCTAssertNotNil(modifiedView, "dismissOnClickOutside should return a modified view")
    }

    func testActionIsNotCalledOnInit() {
        var actionCalled = false
        _ = ClickOutsideModifier { actionCalled = true }
        XCTAssertFalse(actionCalled, "Action should not be called during initialization")
    }
}
