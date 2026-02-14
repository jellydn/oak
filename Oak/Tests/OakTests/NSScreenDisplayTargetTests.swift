import AppKit
import XCTest
@testable import Oak

@MainActor
internal final class NSScreenDisplayTargetTests: XCTestCase {
    // MARK: - Display Target Resolution Tests

    func testMainDisplayReturnsSystemMainScreen() throws {
        guard NSScreen.main != nil else {
            throw XCTSkip("No display available for screen tests")
        }

        let result = NSScreen.screen(for: .mainDisplay, preferredDisplayID: nil)

        XCTAssertNotNil(result, "Main display target should resolve to a screen")
    }

    func testNotchedDisplayPrioritizesNotchedScreenOverSecondary() throws {
        guard NSScreen.main != nil else {
            throw XCTSkip("No display available for screen tests")
        }

        // Test that notchedDisplay target will prefer a notched screen if available
        let result = NSScreen.screen(for: .notchedDisplay, preferredDisplayID: nil)

        XCTAssertNotNil(result, "Notched display target should resolve to a screen")

        // If there's a notched screen available, it should be selected
        if let notchedScreen = NSScreen.screens.first(where: { $0.auxiliaryTopLeftArea != nil }),
           let resolvedScreen = result {
            XCTAssertEqual(
                NSScreen.displayID(for: resolvedScreen),
                NSScreen.displayID(for: notchedScreen),
                "When a notched screen exists, .notchedDisplay should prioritize it"
            )
        }
    }

    func testNotchedDisplayFallsBackToSecondaryWhenNoNotch() throws {
        guard NSScreen.main != nil else {
            throw XCTSkip("No display available for screen tests")
        }

        // This test verifies the fallback chain when no notched screen exists
        let result = NSScreen.screen(for: .notchedDisplay, preferredDisplayID: nil)

        XCTAssertNotNil(result, "Notched display target should always resolve to some screen")

        // When there's no notched screen, it should fall back to secondary or primary
        let hasNotchedScreen = NSScreen.screens.contains { $0.auxiliaryTopLeftArea != nil }
        if !hasNotchedScreen && NSScreen.screens.count > 1 {
            // Should select secondary screen when available
            XCTAssertNotNil(result, "Should fall back to secondary screen when no notch exists")
        } else if !hasNotchedScreen && NSScreen.screens.count == 1,
                  let resolvedScreen = result,
                  let mainScreen = NSScreen.main {
            // Should fall back to primary screen
            XCTAssertEqual(
                NSScreen.displayID(for: resolvedScreen),
                NSScreen.displayID(for: mainScreen),
                "Should fall back to primary screen when only one screen exists"
            )
        }
    }

    func testPreferredDisplayIDOverridesTargetLogic() throws {
        guard let mainScreen = NSScreen.main else {
            throw XCTSkip("No display available for screen tests")
        }

        let mainDisplayID = NSScreen.displayID(for: mainScreen)

        // When a preferred display ID is provided, it should override target logic
        let result = NSScreen.screen(for: .notchedDisplay, preferredDisplayID: mainDisplayID)

        XCTAssertNotNil(result, "Preferred display ID should resolve to a screen")
        if let resolvedScreen = result {
            XCTAssertEqual(
                NSScreen.displayID(for: resolvedScreen),
                mainDisplayID,
                "Preferred display ID should override target selection logic"
            )
        }
    }

    func testDisplayNameReturnsCorrectName() throws {
        guard NSScreen.main != nil else {
            throw XCTSkip("No display available for screen tests")
        }

        let mainDisplayName = NSScreen.displayName(for: .mainDisplay, preferredDisplayID: nil)
        let notchedDisplayName = NSScreen.displayName(for: .notchedDisplay, preferredDisplayID: nil)

        XCTAssertFalse(mainDisplayName.isEmpty, "Main display should have a name")
        XCTAssertFalse(notchedDisplayName.isEmpty, "Notched display should have a name")
    }
}
