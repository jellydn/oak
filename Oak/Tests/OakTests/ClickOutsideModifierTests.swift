import AppKit
import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class ClickOutsideModifierTests: XCTestCase {
    // MARK: - Modifier Initialization

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
        _ = ClickOutsideModifier { wasCalled = true }
        XCTAssertFalse(wasCalled)
    }

    func testDismissalIsDisabledWhilePresentedWindowRequiresInteraction() {
        var isSuppressed = false
        let binding = Binding(
            get: { isSuppressed },
            set: { isSuppressed = $0 }
        )
        let modifier = ClickOutsideModifier(isDismissalSuppressed: binding) {}

        XCTAssertTrue(modifier.isDismissalEnabled)
        isSuppressed = true
        XCTAssertFalse(modifier.isDismissalEnabled)
    }

    // MARK: - View Type Compatibility

    func testModifierCanBeAppliedToText() {
        let view = Text("Hello").dismissOnClickOutside {}
        XCTAssertNotNil(view)
    }

    func testModifierCanBeAppliedToButton() {
        let view = Button("Click") {}.dismissOnClickOutside {}
        XCTAssertNotNil(view)
    }

    func testModifierCanBeAppliedToVStack() {
        let view = VStack { EmptyView() }.dismissOnClickOutside {}
        XCTAssertNotNil(view)
    }

    func testModifierCanBeAppliedToHStack() {
        let view = HStack { Text("A")
            Text("B")
        }.dismissOnClickOutside {}
        XCTAssertNotNil(view)
    }

    func testModifierCanBeAppliedToZStack() {
        let view = ZStack { Color.clear }.dismissOnClickOutside {}
        XCTAssertNotNil(view)
    }

    func testModifierCanBeAppliedToNestedViews() {
        let view = VStack {
            HStack { Text("Inner") }
        }
        .dismissOnClickOutside {}
        XCTAssertNotNil(view)
    }

    // MARK: - Multiple Modifiers

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

    // MARK: - View Extension

    func testDismissOnClickOutsideReturnsModifiedView() {
        let view = Text("Test").dismissOnClickOutside {}
        XCTAssertNotNil(view)
    }

    func testDismissOnClickOutsideChaining() {
        let view = Text("Test")
            .dismissOnClickOutside {}
            .dismissOnClickOutside {}
        XCTAssertNotNil(view)
    }
}

@MainActor
internal final class AudioMenuViewTests: XCTestCase {
    func testImportCancellationDoesNotShowError() {
        XCTAssertNil(AudioMenuView.importErrorMessage(for: CancellationError()))

        let cocoaCancellation = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError)
        XCTAssertNil(AudioMenuView.importErrorMessage(for: cocoaCancellation))
    }

    func testImportFailureShowsError() {
        let failure = NSError(
            domain: "AudioMenuViewTests",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Import failed"]
        )

        XCTAssertEqual(AudioMenuView.importErrorMessage(for: failure), "Import failed")
    }
}
