import AppKit
import XCTest
@testable import Oak

@MainActor
internal extension NotchWindowControllerTests {
    // MARK: - Notch-First UI Tests

    func testWindowPositionsAtTopOfScreenOnNotchedDisplay() throws {
        // Skip if no notched display available
        guard let notchedScreen = NSScreen.screens.first(where: { $0.hasNotch }) else {
            throw XCTSkip("No notched display available for testing")
        }

        // Create a window controller targeting the notched display
        let notchedPresetSettings = PresetSettingsStore(userDefaults: testUserDefaults)
        let notchedScreenID = NSScreen.displayID(for: notchedScreen)
        notchedPresetSettings.setDisplayTarget(.notchedDisplay, screenID: notchedScreenID)
        notchedPresetSettings.setAlwaysOnTop(false)

        let notchedController = NotchWindowController(presetSettings: notchedPresetSettings)
        defer { notchedController.cleanup() }

        let window = notchedController.window as? NotchWindow

        let activeScreen = NSScreen.screen(for: .notchedDisplay, preferredDisplayID: notchedScreenID) ?? notchedScreen

        // Calculate all possible valid Y positions for this configuration
        let expectedYPositions = [
            NotchWindow.calculateYPosition(
                for: activeScreen,
                height: NotchLayout.height,
                alwaysOnTop: false,
                showBelowNotch: false
            ),
            NotchWindow.calculateYPosition(
                for: activeScreen,
                height: NotchLayout.height,
                alwaysOnTop: false,
                showBelowNotch: true
            )
        ]

        // Wait for window to be positioned
        var actualY: CGFloat = 0
        var positionUpdated = false
        let endTime = Date().addingTimeInterval(1.0)

        while Date() < endTime {
            actualY = window?.frame.minY ?? 0
            if expectedYPositions.contains(where: { abs(actualY - $0) <= 1.0 }) {
                positionUpdated = true
                break
            }
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }

        XCTAssertTrue(
            positionUpdated,
            "Window should be positioned at one of the expected Y positions "
                + "\(expectedYPositions), but was at Y=\(actualY)"
        )
    }

    func testWindowPositionsBelowMenuBarOnNonNotchedDisplayWithAlwaysOnTop() {
        // Enable alwaysOnTop to test positioning below menu bar
        presetSettings.setAlwaysOnTop(true)

        let window = windowController.window as? NotchWindow
        let target = presetSettings.displayTarget
        let preferredDisplayID = presetSettings.preferredDisplayID(for: target)
        let resolvedScreen = NSScreen.screen(for: target, preferredDisplayID: preferredDisplayID)

        // Wait for window to reposition
        var positionUpdated = false
        let endTime = Date().addingTimeInterval(1.0)

        while Date() < endTime {
            if let screen = resolvedScreen {
                // Use the shared positioning logic to calculate expected position
                let expectedY = NotchWindow.calculateYPosition(
                    for: screen,
                    height: NotchLayout.height,
                    alwaysOnTop: presetSettings.alwaysOnTop,
                    showBelowNotch: presetSettings.showBelowNotch
                )

                if abs((window?.frame.minY ?? 0) - expectedY) <= 1.0 {
                    positionUpdated = true
                    break
                }
            }
            RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        }

        XCTAssertTrue(positionUpdated, "Window should reposition based on notch detection and alwaysOnTop setting")
    }

    func testNotchedDisplayTargetFindsNotchedScreen() throws {
        guard NSScreen.screens.contains(where: \.hasNotch) else {
            throw XCTSkip("No notched display available for testing")
        }

        let notchedScreen = NSScreen.screens.first { $0.hasNotch }
        let targetScreen = NSScreen.screen(for: .notchedDisplay)

        XCTAssertNotNil(targetScreen, "Should resolve a screen for notchedDisplay target")
        XCTAssertEqual(
            targetScreen,
            notchedScreen,
            "notchedDisplay target should prefer screen with actual notch"
        )
    }
}
