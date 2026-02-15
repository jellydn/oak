import AppKit
import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class NotchWindowControllerTests: XCTestCase {
    var windowController: NotchWindowController!
    var testUserDefaults: UserDefaults!
    private var suiteName: String!
    var presetSettings: PresetSettingsStore!

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
}

@MainActor
internal extension NotchWindowControllerTests {
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
}

@MainActor
internal extension NotchWindowControllerTests {
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
            if let window = windowController.window as? NotchWindow, abs(window.frame.width - width) <= 1.0 {
                return true
            }
            RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        }
        return false
    }

    func resolvedDisplayFrame() -> NSRect {
        let target = presetSettings.displayTarget
        let preferredDisplayID = presetSettings.preferredDisplayID(for: target)
        return NSScreen.screen(for: target, preferredDisplayID: preferredDisplayID)?.frame ?? .zero
    }
}
