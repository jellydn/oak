import AppKit
import XCTest
@testable import Oak

@MainActor
internal final class NSScreenNotchTests: XCTestCase {
    // MARK: - Display UUID Tests

    func testDisplayUUIDIsNotNil() throws {
        guard let mainScreen = NSScreen.main else {
            throw XCTSkip("No main screen available for testing")
        }

        let uuid = mainScreen.displayUUID

        XCTAssertNotNil(uuid, "Display UUID should not be nil for main screen")
        XCTAssertFalse(uuid?.isEmpty ?? true, "Display UUID should not be empty")
    }

    func testDisplayUUIDIsPersistent() throws {
        guard let mainScreen = NSScreen.main else {
            throw XCTSkip("No main screen available for testing")
        }

        let uuid1 = mainScreen.displayUUID
        let uuid2 = mainScreen.displayUUID

        XCTAssertEqual(uuid1, uuid2, "Display UUID should be consistent across multiple calls")
    }

    func testScreenLookupByUUID() throws {
        guard let mainScreen = NSScreen.main, let uuid = mainScreen.displayUUID else {
            throw XCTSkip("No main screen or UUID available for testing")
        }

        let foundScreen = NSScreen.screen(withUUID: uuid)

        XCTAssertNotNil(foundScreen, "Should be able to find screen by UUID")
        XCTAssertEqual(foundScreen, mainScreen, "Found screen should match the original screen")
    }

    func testScreensByUUIDContainsAllScreens() {
        let screens = NSScreen.screens
        let screensByUUID = NSScreen.screensByUUID

        // screensByUUID should contain an entry for each screen that has a valid UUID
        // The count should be equal or potentially less if some screens lack UUIDs
        XCTAssertLessThanOrEqual(
            screensByUUID.count,
            screens.count,
            "screensByUUID should not contain more entries than available screens"
        )

        for screen in screens {
            guard let uuid = screen.displayUUID else { continue }
            XCTAssertNotNil(
                screensByUUID[uuid],
                "screensByUUID should contain entry for screen with UUID \(uuid)"
            )
        }
    }

    func testUUIDCacheUpdatesOnScreenChange() throws {
        let initialCache = NSScreen.screensByUUID
        guard let mainScreen = NSScreen.main, let mainUUID = mainScreen.displayUUID else {
            throw XCTSkip("No main screen or UUID available for testing")
        }

        // Verify main screen is initially in cache
        XCTAssertNotNil(
            initialCache[mainUUID],
            "Main screen UUID should be present in initial cache"
        )

        // Simulate screen configuration change
        NotificationCenter.default.post(
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // Give the cache time to rebuild
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        let updatedCache = NSScreen.screensByUUID

        // Verify main screen UUID is still present after cache rebuild
        XCTAssertNotNil(
            updatedCache[mainUUID],
            "Main screen UUID should still be present in cache after screen configuration change"
        )
    }

    // MARK: - Notch Detection Tests

    func testHasNotchProperty() throws {
        guard let mainScreen = NSScreen.main else {
            throw XCTSkip("No main screen available for testing")
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

        if let notchedScreen {
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
        if let notchedScreen {
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
