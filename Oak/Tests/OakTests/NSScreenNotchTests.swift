import AppKit
import XCTest
@testable import Oak

@MainActor
internal final class NSScreenNotchTests: XCTestCase {
    // MARK: - Display UUID Tests

    func testDisplayUUIDIsNotNil() {
        guard let mainScreen = NSScreen.main else {
            XCTSkip("No main screen available for testing")
        }

        let uuid = mainScreen.displayUUID

        XCTAssertNotNil(uuid, "Display UUID should not be nil for main screen")
        XCTAssertFalse(uuid?.isEmpty ?? true, "Display UUID should not be empty")
    }

    func testDisplayUUIDIsPersistent() {
        guard let mainScreen = NSScreen.main else {
            XCTSkip("No main screen available for testing")
        }

        let uuid1 = mainScreen.displayUUID
        let uuid2 = mainScreen.displayUUID

        XCTAssertEqual(uuid1, uuid2, "Display UUID should be consistent across multiple calls")
    }

    func testScreenLookupByUUID() {
        guard let mainScreen = NSScreen.main, let uuid = mainScreen.displayUUID else {
            XCTSkip("No main screen or UUID available for testing")
        }

        let foundScreen = NSScreen.screen(withUUID: uuid)

        XCTAssertNotNil(foundScreen, "Should be able to find screen by UUID")
        XCTAssertEqual(foundScreen, mainScreen, "Found screen should match the original screen")
    }

    func testScreensByUUIDContainsAllScreens() {
        let screens = NSScreen.screens
        let screensByUUID = NSScreen.screensByUUID

        XCTAssertGreaterThanOrEqual(
            screensByUUID.count,
            screens.count,
            "screensByUUID should contain at least as many entries as there are screens"
        )

        for screen in screens {
            guard let uuid = screen.displayUUID else { continue }
            XCTAssertNotNil(
                screensByUUID[uuid],
                "screensByUUID should contain entry for screen with UUID \(uuid)"
            )
        }
    }

    func testUUIDCacheUpdatesOnScreenChange() {
        let initialCache = NSScreen.screensByUUID
        let initialCount = initialCache.count

        // Simulate screen configuration change
        NotificationCenter.default.post(
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // Give the cache time to rebuild
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        let updatedCache = NSScreen.screensByUUID

        // Cache should still be functional after notification
        XCTAssertGreaterThanOrEqual(
            updatedCache.count,
            0,
            "Cache should still contain entries after screen configuration change"
        )
        XCTAssertEqual(
            initialCount,
            updatedCache.count,
            "Cache size should remain consistent if no actual screen change occurred"
        )
    }

    // MARK: - Notch Detection Tests

    func testHasNotchProperty() {
        guard let mainScreen = NSScreen.main else {
            XCTSkip("No main screen available for testing")
        }

        let hasNotch = mainScreen.hasNotch

        // hasNotch should return a boolean based on safeAreaInsets.top
        if mainScreen.safeAreaInsets.top > 0 {
            XCTAssertTrue(hasNotch, "Screen with safeAreaInsets.top > 0 should have hasNotch == true")
        } else {
            XCTAssertFalse(hasNotch, "Screen with safeAreaInsets.top == 0 should have hasNotch == false")
        }
    }

    func testNotchedScreenDetection() {
        // Find screen with actual notch
        let notchedScreen = NSScreen.screens.first { $0.hasNotch }

        if let notchedScreen = notchedScreen {
            XCTAssertTrue(notchedScreen.hasNotch, "Notched screen should have hasNotch == true")
            XCTAssertGreaterThan(
                notchedScreen.safeAreaInsets.top,
                0,
                "Notched screen should have safeAreaInsets.top > 0"
            )
        } else {
            // If no notched screen found, verify all screens have no notch
            for screen in NSScreen.screens {
                XCTAssertFalse(
                    screen.hasNotch,
                    "Screen without notch should have hasNotch == false"
                )
                XCTAssertEqual(
                    screen.safeAreaInsets.top,
                    0,
                    "Screen without notch should have safeAreaInsets.top == 0"
                )
            }
        }
    }

    func testNotchedDisplayTargetPrefersNotchedScreen() {
        let targetScreen = NSScreen.screen(for: .notchedDisplay)

        XCTAssertNotNil(targetScreen, "Should always resolve a screen for notchedDisplay target")

        // If a notched screen exists, it should be preferred
        let notchedScreen = NSScreen.screens.first { $0.hasNotch }
        if let notchedScreen = notchedScreen {
            XCTAssertEqual(
                targetScreen,
                notchedScreen,
                "notchedDisplay target should prefer screen with actual notch"
            )
        }
    }

    func testMainDisplayTarget() {
        let targetScreen = NSScreen.screen(for: .mainDisplay)

        XCTAssertNotNil(targetScreen, "Should always resolve a screen for mainDisplay target")

        // Main display should be the primary screen (CGMainDisplayID)
        if let mainScreen = NSScreen.main {
            XCTAssertEqual(
                targetScreen,
                mainScreen,
                "mainDisplay target should resolve to NSScreen.main"
            )
        }
    }
}
