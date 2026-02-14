import AppKit
import XCTest
@testable import Oak

@MainActor
internal final class NotchWindowControllerGeometryTests: XCTestCase {
    private var windowController: NotchWindowController!
    private var testUserDefaults: UserDefaults!
    private var suiteName: String!
    private var presetSettings: PresetSettingsStore!

    override func setUp() async throws {
        guard NSScreen.main != nil else {
            throw XCTSkip("No display available for window tests")
        }
        suiteName = "OakTests.NotchWindowControllerGeometry.\(UUID().uuidString)"
        testUserDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        testUserDefaults.removePersistentDomain(forName: suiteName)
        presetSettings = PresetSettingsStore(userDefaults: testUserDefaults)
        presetSettings.setDisplayTarget(.mainDisplay, screenID: CGMainDisplayID())
        windowController = NotchWindowController(presetSettings: presetSettings)
    }

    override func tearDown() async throws {
        windowController.cleanup()
        windowController = nil
        presetSettings = nil
        testUserDefaults.removePersistentDomain(forName: suiteName)
        testUserDefaults = nil
        suiteName = nil
    }

    func testYPositionTopAnchorsForInsideNotchMode() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1512, height: 982)
        let leftArea = NSRect(x: 0, y: 944, width: 600, height: 38)
        let rightArea = NSRect(x: 912, y: 944, width: 600, height: 38)

        let yPosition = NotchWindow.yPosition(
            screenFrame: screenFrame,
            auxiliaryTopLeftArea: leftArea,
            auxiliaryTopRightArea: rightArea,
            height: NotchLayout.height,
            mode: .insideNotch
        )

        XCTAssertEqual(
            yPosition,
            949,
            accuracy: 0.1,
            "Inside notch mode should stay top-anchored to avoid clipping/cutoff artifacts"
        )
    }

    func testYPositionUsesNotchBandBottomForBelowNotchMode() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1512, height: 982)
        let leftArea = NSRect(x: 0, y: 944, width: 600, height: 38)
        let rightArea = NSRect(x: 912, y: 944, width: 600, height: 38)

        let yPosition = NotchWindow.yPosition(
            screenFrame: screenFrame,
            auxiliaryTopLeftArea: leftArea,
            auxiliaryTopRightArea: rightArea,
            height: NotchLayout.height,
            mode: .belowNotch
        )

        XCTAssertEqual(yPosition, 911, accuracy: 0.1, "Panel should be anchored below notch/menu-bar band")
    }

    func testYPositionFallsBackToTopAnchorWhenNoAuxiliaryAreas() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1920, height: 1080)

        let yPosition = NotchWindow.yPosition(
            screenFrame: screenFrame,
            auxiliaryTopLeftArea: nil,
            auxiliaryTopRightArea: nil,
            height: NotchLayout.height,
            mode: .belowNotch
        )

        XCTAssertEqual(yPosition, 1047, accuracy: 0.1, "Panel should remain top-anchored on non-notched displays")
    }

    func testCollapsedSizeUsesNotchGeometryWhenAvailable() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1512, height: 982)
        let visibleFrame = NSRect(x: 0, y: 0, width: 1512, height: 944)
        let leftArea = NSRect(x: 0, y: 944, width: 640, height: 38)
        let rightArea = NSRect(x: 872, y: 944, width: 640, height: 38)

        let size = NotchWindow.collapsedSize(
            screenFrame: screenFrame,
            visibleFrame: visibleFrame,
            safeAreaTopInset: 38,
            auxiliaryTopLeftArea: leftArea,
            auxiliaryTopRightArea: rightArea
        )

        XCTAssertEqual(size.width, 236, accuracy: 0.1)
        XCTAssertEqual(size.height, 38, accuracy: 0.1)
    }

    func testCollapsedSizeFallsBackWhenNotchGeometryUnavailable() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let visibleFrame = NSRect(x: 0, y: 0, width: 1920, height: 1056)

        let size = NotchWindow.collapsedSize(
            screenFrame: screenFrame,
            visibleFrame: visibleFrame,
            safeAreaTopInset: 0,
            auxiliaryTopLeftArea: nil,
            auxiliaryTopRightArea: nil
        )

        XCTAssertEqual(size.width, NotchLayout.collapsedWidth, accuracy: 0.1)
        XCTAssertEqual(size.height, NotchLayout.height, accuracy: 0.1)
    }

    func testCollapsedSizeUsesAuxiliaryBandHeightWhenSafeAreaIsZero() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1512, height: 982)
        let visibleFrame = NSRect(x: 0, y: 0, width: 1512, height: 958)
        let leftArea = NSRect(x: 0, y: 944, width: 640, height: 38)
        let rightArea = NSRect(x: 872, y: 944, width: 640, height: 38)

        let size = NotchWindow.collapsedSize(
            screenFrame: screenFrame,
            visibleFrame: visibleFrame,
            safeAreaTopInset: 0,
            auxiliaryTopLeftArea: leftArea,
            auxiliaryTopRightArea: rightArea
        )

        XCTAssertEqual(size.width, 236, accuracy: 0.1)
        XCTAssertEqual(size.height, 38, accuracy: 0.1, "Auxiliary notch-band height should drive collapsed height")
    }

    func testObserverIsRegisteredForScreenChanges() {
        let expectation = expectation(description: "Screen configuration change notification")

        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSApplication.didChangeScreenParametersNotification,
                object: NSApp
            )
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        XCTAssertNotNil(windowController.window, "Window should still exist after screen change notification")
    }

    func testWindowRepositionsOnScreenConfigurationChange() {
        let window = windowController.window as? NotchWindow

        triggerExpansion(true)

        NotificationCenter.default.post(
            name: NSApplication.didChangeScreenParametersNotification,
            object: NSApp
        )

        _ = waitForFrameWidth(NotchLayout.expandedWidth, timeout: 1.0)

        let finalFrame = window?.frame ?? .zero
        XCTAssertEqual(
            finalFrame.width,
            NotchLayout.expandedWidth,
            accuracy: 1.0,
            "Window should maintain expanded width after screen change"
        )
        XCTAssertGreaterThan(finalFrame.height, 0, "Window should have valid height after screen change")
    }

    func testCleanupRemovesScreenChangeObserver() {
        XCTAssertNoThrow(windowController.cleanup(), "Cleanup should remove observer without crashing")

        XCTAssertNoThrow(
            NotificationCenter.default.post(
                name: NSApplication.didChangeScreenParametersNotification,
                object: NSApp
            ),
            "Posting notification after cleanup should not crash"
        )
    }
}

private extension NotchWindowControllerGeometryTests {
    func triggerExpansion(_ expanded: Bool) {
        windowController.handleExpansionChange(expanded)
        let targetWidth: CGFloat = expanded ? NotchLayout.expandedWidth : NotchLayout.collapsedWidth
        if !waitForFrameWidth(targetWidth, timeout: 1.0) {
            windowController.handleExpansionChange(expanded)
            _ = waitForFrameWidth(targetWidth, timeout: 1.0)
        }
    }

    @discardableResult
    func waitForFrameWidth(_ width: CGFloat, timeout: TimeInterval) -> Bool {
        let endTime = Date().addingTimeInterval(timeout)

        while Date() < endTime {
            if let window = windowController.window as? NotchWindow,
               abs(window.frame.width - width) <= 1.0 {
                return true
            }

            RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        }

        return false
    }
}
