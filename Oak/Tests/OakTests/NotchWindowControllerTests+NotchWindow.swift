import AppKit
import XCTest
@testable import Oak

@MainActor
internal extension NotchWindowControllerTests {
    // MARK: - NotchWindow Tests

    func testNotchWindowHasCorrectStyleMask() {
        let window = windowController.window as? NotchWindow

        let expectedStyleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel]
        XCTAssertEqual(
            window?.styleMask,
            expectedStyleMask,
            "NotchWindow should have borderless and non-activating style"
        )
    }

    func testNotchWindowIsFloating() {
        let window = windowController.window as? NotchWindow

        XCTAssertEqual(window?.level, .floating, "NotchWindow should have floating level by default")
    }

    func testNotchWindowIsStatusBarWhenAlwaysOnTopEnabled() {
        presetSettings.setAlwaysOnTop(true)

        // Poll for window level change
        let window = windowController.window as? NotchWindow
        var levelChanged = false
        let endTime = Date().addingTimeInterval(1.0)

        while Date() < endTime {
            if window?.level == .statusBar {
                levelChanged = true
                break
            }
            RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        }

        XCTAssertTrue(levelChanged, "NotchWindow should have statusBar level when alwaysOnTop is enabled")
        XCTAssertEqual(window?.level, .statusBar, "NotchWindow should have statusBar level when alwaysOnTop is enabled")
    }

    func testNotchWindowMovesToVisibleFrameWhenAlwaysOnTopEnabled() {
        let window = windowController.window as? NotchWindow

        presetSettings.setAlwaysOnTop(true)

        let target = presetSettings.displayTarget
        let preferredDisplayID = presetSettings.preferredDisplayID(for: target)
        let resolvedScreen = NSScreen.screen(for: target, preferredDisplayID: preferredDisplayID)
        let expectedY = (resolvedScreen?.visibleFrame.maxY ?? 0) - NotchLayout.height

        var yPositionMatchesVisibleFrame = false
        let endTime = Date().addingTimeInterval(1.0)

        while Date() < endTime {
            if abs((window?.frame.minY ?? 0) - expectedY) <= 1.0 {
                yPositionMatchesVisibleFrame = true
                break
            }
            RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        }

        XCTAssertTrue(
            yPositionMatchesVisibleFrame,
            "NotchWindow should align to visibleFrame top when alwaysOnTop is enabled"
        )
    }

    func testNotchWindowReturnsToFloatingWhenAlwaysOnTopDisabled() {
        let window = windowController.window as? NotchWindow

        // First enable
        presetSettings.setAlwaysOnTop(true)
        var levelChangedToStatusBar = false
        var endTime = Date().addingTimeInterval(1.0)

        while Date() < endTime {
            if window?.level == .statusBar {
                levelChangedToStatusBar = true
                break
            }
            RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        }
        XCTAssertTrue(levelChangedToStatusBar, "Window should change to statusBar level")

        // Then disable
        presetSettings.setAlwaysOnTop(false)
        var levelChangedToFloating = false
        endTime = Date().addingTimeInterval(1.0)

        while Date() < endTime {
            if window?.level == .floating {
                levelChangedToFloating = true
                break
            }
            RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        }

        XCTAssertTrue(levelChangedToFloating, "Window should change back to floating level")
        XCTAssertEqual(
            window?.level,
            .floating,
            "NotchWindow should return to floating level when alwaysOnTop is disabled"
        )
    }

    func testNotchWindowJoinsAllSpaces() {
        let window = windowController.window as? NotchWindow

        let expectedBehavior: NSWindow.CollectionBehavior = [.canJoinAllSpaces, .stationary]
        XCTAssertEqual(
            window?.collectionBehavior,
            expectedBehavior,
            "NotchWindow should join all spaces and remain stationary"
        )
    }

    func testNotchWindowHasTransparentBackground() {
        let window = windowController.window as? NotchWindow

        XCTAssertFalse(window?.isOpaque ?? true, "NotchWindow should not be opaque")
        XCTAssertFalse(window?.hasShadow ?? true, "NotchWindow should not have shadow")
        XCTAssertEqual(window?.backgroundColor, .clear, "NotchWindow should have clear background color")
    }

    func testNotchWindowReceivesMouseEvents() {
        let window = windowController.window as? NotchWindow

        XCTAssertFalse(window?.ignoresMouseEvents ?? true, "NotchWindow should accept mouse events")
    }
}
