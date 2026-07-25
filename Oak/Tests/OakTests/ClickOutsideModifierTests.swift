import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class ClickOutsideModifierTests: XCTestCase {
    func testModifierInitialization() {
        let modifier = ClickOutsideModifier {}
        XCTAssertNotNil(modifier)
    }

    func testViewExtensionExists() {
        let view = Text("Test").dismissOnClickOutside {}
        XCTAssertNotNil(view)
    }

    func testActionIsNotCalledOnInit() {
        var wasCalled = false
        _ = ClickOutsideModifier {
            wasCalled = true
        }
        XCTAssertFalse(wasCalled, "Action should not be called during initialization")
    }

    func testModifierCanBeAppliedToButton() {
        let view = Button("Click") {}.dismissOnClickOutside {}
        XCTAssertNotNil(view)
    }

    func testModifierCanBeAppliedToStack() {
        let view = VStack { EmptyView() }.dismissOnClickOutside {}
        XCTAssertNotNil(view)
    }

    func testMultipleModifiersWithDifferentActions() {
        var firstCalled = false
        var secondCalled = false

        let modifier1 = ClickOutsideModifier { firstCalled = true }
        let modifier2 = ClickOutsideModifier { secondCalled = true }

        XCTAssertNotNil(modifier1)
        XCTAssertNotNil(modifier2)
        XCTAssertFalse(firstCalled)
        XCTAssertFalse(secondCalled)
    }
}
