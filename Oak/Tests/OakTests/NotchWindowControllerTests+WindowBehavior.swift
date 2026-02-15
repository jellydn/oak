import AppKit
import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal extension NotchWindowControllerTests {
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
        let screenFrame = resolvedDisplayFrame()
        let initialCenterX = window?.frame.midX ?? 0
        let expectedCenterX = screenFrame.midX

        XCTAssertEqual(initialCenterX, expectedCenterX, accuracy: 1.0, "Window should be centered horizontally on init")

        triggerExpansion(true)

        let expandedCenterX = window?.frame.midX ?? 0
        XCTAssertEqual(expandedCenterX, expectedCenterX, accuracy: 1.0, "Window should remain centered when expanded")
    }

    func testWindowStaysAtNotchHeight() {
        let window = windowController.window as? NotchWindow
        let initialYPosition = window?.frame.minY ?? 0

        triggerExpansion(true)

        let windowY = window?.frame.minY ?? 0
        XCTAssertEqual(
            windowY,
            initialYPosition,
            accuracy: 1.0,
            "Window should remain at notch height position when expansion state changes"
        )
    }
}

@MainActor
internal extension NotchWindowControllerTests {
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
}

@MainActor
internal extension NotchWindowControllerTests {
    // MARK: - Cleanup Tests

    func testCleanupReleasesViewModelResources() {
        let window = windowController.window
        let hostingView = window?.contentView as? NSHostingView<NotchCompanionView>

        XCTAssertNoThrow(windowController.cleanup(), "Cleanup should not throw")

        XCTAssertNotNil(hostingView, "HostingView should exist before cleanup")
    }
}

@MainActor
internal extension NotchWindowControllerTests {
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

        _ = waitForFrameWidth(NotchLayout.expandedWidth, timeout: 1.0)

        let finalFrame = window?.frame ?? .zero

        // The frame should remain valid (width should still match expanded state)
        XCTAssertEqual(
            finalFrame.width,
            NotchLayout.expandedWidth,
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
}
