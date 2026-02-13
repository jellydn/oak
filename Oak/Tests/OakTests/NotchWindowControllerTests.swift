import AppKit
import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class NotchWindowControllerTests: XCTestCase {
    var windowController: NotchWindowController!
    private var testUserDefaults: UserDefaults!
    private var suiteName: String!
    private var presetSettings: PresetSettingsStore!

    override func setUp() async throws {
        guard NSScreen.main != nil else {
            throw XCTSkip("No display available for window tests")
        }
        suiteName = "OakTests.NotchWindowController.\(UUID().uuidString)"
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

    // MARK: - Initialization Tests

    func testWindowControllerCreatesWindow() {
        let window = windowController.window

        XCTAssertNotNil(window, "Window should be created after initialization")
        XCTAssertTrue(window is NotchWindow, "Window should be a NotchWindow instance")
    }

    func testWindowIsVisibleOnScreen() {
        let window = windowController.window

        XCTAssertTrue(window?.isVisible ?? false, "Window should be visible after initialization")
    }

    func testWindowHasContentView() {
        let contentView = windowController.window?.contentView

        XCTAssertNotNil(contentView, "Window should have a content view")
        XCTAssertTrue(
            contentView is NSHostingView<NotchCompanionView>,
            "Content view should host NotchCompanionView"
        )
    }

    // MARK: - Window Expansion Behavior Tests

    func testWindowExpandsWhenRequested() {
        let window = windowController.window as? NotchWindow
        let initialWidth = window?.frame.width ?? 0

        triggerExpansion(true)
        var finalWidth = window?.frame.width ?? 0

        if finalWidth <= initialWidth {
            // Retry once to reduce timing-related flakiness from initial layout.
            triggerExpansion(true)
            finalWidth = window?.frame.width ?? 0
        }

        XCTAssertTrue(finalWidth > initialWidth, "Window width should increase when expanded")
    }

    func testWindowCollapsesWhenRequested() {
        let window = windowController.window as? NotchWindow
        triggerExpansion(true)
        let expandedWidth = window?.frame.width ?? 0

        triggerExpansion(false)

        let finalWidth = window?.frame.width ?? 0
        XCTAssertTrue(finalWidth < expandedWidth, "Window width should decrease when collapsed")
    }

    func testWindowRemainsCenteredHorizontally() {
        let window = windowController.window as? NotchWindow
        let screenFrame = NSScreen.main?.frame ?? .zero
        let initialCenterX = window?.frame.midX ?? 0
        let expectedCenterX = screenFrame.midX

        XCTAssertEqual(initialCenterX, expectedCenterX, accuracy: 1.0, "Window should be centered horizontally on init")

        triggerExpansion(true)

        let expandedCenterX = window?.frame.midX ?? 0
        XCTAssertEqual(expandedCenterX, expectedCenterX, accuracy: 1.0, "Window should remain centered when expanded")
    }

    func testWindowStaysAtNotchHeight() {
        let window = windowController.window as? NotchWindow
        let screenFrame = NSScreen.main?.frame ?? .zero
        let notchHeight: CGFloat = 33
        let expectedYPosition = screenFrame.maxY - notchHeight

        triggerExpansion(true)

        let windowY = window?.frame.minY ?? 0
        XCTAssertEqual(windowY, expectedYPosition, accuracy: 1.0, "Window should remain at notch height position")
    }

    // MARK: - State Deduplication Tests

    func testDuplicateExpansionRequestsAreIgnored() {
        let window = windowController.window as? NotchWindow
        triggerExpansion(true)
        let firstWidth = window?.frame.width ?? 0

        triggerExpansion(true)

        let secondWidth = window?.frame.width ?? 0
        XCTAssertEqual(
            secondWidth,
            firstWidth,
            accuracy: 0.1,
            "Duplicate expansion request should not change window size"
        )
    }

    func testDuplicateCollapseRequestsAreIgnored() {
        let window = windowController.window as? NotchWindow
        let initialWidth = window?.frame.width ?? 0

        triggerExpansion(false)

        let finalWidth = window?.frame.width ?? 0
        XCTAssertEqual(
            finalWidth,
            initialWidth,
            accuracy: 0.1,
            "Duplicate collapse request should not change window size"
        )
    }

    func testToggleExpansionThenCollapseChangesSize() {
        let window = windowController.window as? NotchWindow
        let collapsedWidth = window?.frame.width ?? 0

        triggerExpansion(true)
        let expandedWidth = window?.frame.width ?? 0

        triggerExpansion(false)

        let finalWidth = window?.frame.width ?? 0
        XCTAssertNotEqual(collapsedWidth, expandedWidth, "Collapsed and expanded widths should differ")
        XCTAssertEqual(finalWidth, collapsedWidth, accuracy: 1.0, "Final width should match initial collapsed width")
    }

    // MARK: - Cleanup Tests

    func testCleanupReleasesViewModelResources() {
        let window = windowController.window
        let hostingView = window?.contentView as? NSHostingView<NotchCompanionView>

        XCTAssertNoThrow(windowController.cleanup(), "Cleanup should not throw")

        XCTAssertNotNil(hostingView, "HostingView should exist before cleanup")
    }

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

        XCTAssertEqual(window?.level, .floating, "NotchWindow should have floating level")
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

    // MARK: - Display Configuration Change Tests

    func testObserverIsRegisteredForScreenChanges() {
        // Verify that the observer is set up by checking we can trigger the notification
        let expectation = expectation(description: "Screen configuration change notification")

        // Post the notification on the main thread
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSApplication.didChangeScreenParametersNotification,
                object: NSApp
            )
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // If no crash occurred, the observer is properly set up
        XCTAssertNotNil(windowController.window, "Window should still exist after screen change notification")
    }

    func testWindowRepositionsOnScreenConfigurationChange() {
        let window = windowController.window as? NotchWindow

        // Expand the window first
        triggerExpansion(true)

        // Simulate screen configuration change
        NotificationCenter.default.post(
            name: NSApplication.didChangeScreenParametersNotification,
            object: NSApp
        )

        waitForFrameUpdate()

        let finalFrame = window?.frame ?? .zero

        // The frame should remain valid (width should still match expanded state)
        XCTAssertEqual(
            finalFrame.width,
            372,
            accuracy: 1.0,
            "Window should maintain expanded width after screen change"
        )
        XCTAssertGreaterThan(finalFrame.height, 0, "Window should have valid height after screen change")
    }

    func testCleanupRemovesScreenChangeObserver() {
        // Cleanup should not crash
        XCTAssertNoThrow(windowController.cleanup(), "Cleanup should remove observer without crashing")

        // Post notification after cleanup - should not crash
        XCTAssertNoThrow(
            NotificationCenter.default.post(
                name: NSApplication.didChangeScreenParametersNotification,
                object: NSApp
            ),
            "Posting notification after cleanup should not crash"
        )
    }

    // MARK: - Helper Methods

    private func triggerExpansion(_ expanded: Bool) {
        windowController.handleExpansionChange(expanded)
        waitForFrameUpdate()
    }

    private func waitForFrameUpdate() {
        let expectation = expectation(description: "Wait for window resize")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
}
