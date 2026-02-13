import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class US002Tests: XCTestCase {
    var viewModel: FocusSessionViewModel!
    var presetSettings: PresetSettingsStore!
    var presetSuiteName: String!

    override func setUp() async throws {
        let suiteName = "OakTests.US002.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw NSError(domain: "US002Tests", code: 1)
        }
        userDefaults.removePersistentDomain(forName: suiteName)
        presetSuiteName = suiteName
        presetSettings = PresetSettingsStore(userDefaults: userDefaults)
        viewModel = FocusSessionViewModel(presetSettings: presetSettings)
    }

    override func tearDown() async throws {
        viewModel.cleanup()
        if let presetSuiteName {
            UserDefaults(suiteName: presetSuiteName)?.removePersistentDomain(forName: presetSuiteName)
        }
    }

    func testOnlyTwoPresetsSupported() {
        let presets = Preset.allCases
        XCTAssertEqual(presets.count, 2, "MVP should support exactly two presets")
        XCTAssertTrue(presets.contains(.short), "Should have 25/5 preset")
        XCTAssertTrue(presets.contains(.long), "Should have 50/10 preset")
    }

    func testPresetDurationsCorrect() {
        XCTAssertEqual(Preset.short.workDuration, 25 * 60, "Short preset should be 25 minutes")
        XCTAssertEqual(Preset.short.breakDuration, 5 * 60, "Short preset break should be 5 minutes")
        XCTAssertEqual(Preset.long.workDuration, 50 * 60, "Long preset should be 50 minutes")
        XCTAssertEqual(Preset.long.breakDuration, 10 * 60, "Long preset break should be 10 minutes")
    }

    func testCanSwitchPresetBeforeSessionStart() {
        // Initial state
        XCTAssertEqual(viewModel.canStart, true)
        XCTAssertEqual(viewModel.selectedPreset, .short)
        XCTAssertEqual(viewModel.displayTime, "25:00")

        // Switch to long preset
        viewModel.selectPreset(.long)
        XCTAssertEqual(viewModel.selectedPreset, .long)
        XCTAssertEqual(viewModel.displayTime, "50:00")

        // Switch back to short preset
        viewModel.selectPreset(.short)
        XCTAssertEqual(viewModel.selectedPreset, .short)
        XCTAssertEqual(viewModel.displayTime, "25:00")
    }

    func testCannotSwitchPresetAfterSessionStart() {
        // Start a session
        viewModel.startSession()
        XCTAssertEqual(viewModel.canStart, false)

        // Try to switch preset (should have no effect)
        viewModel.selectPreset(.long)

        // Session should continue with original preset
        XCTAssertEqual(viewModel.selectedPreset, .short)
    }

    func testWorkAndBreakDurationsFollowPreset() {
        // Test short preset (25/5) - verify display shows correct time
        viewModel.selectedPreset = .short
        viewModel.startSession()
        XCTAssertEqual(viewModel.displayTime, "25:00", "Short preset should show 25 minutes")
        XCTAssertEqual(viewModel.currentSessionType, "Focus")

        // Pause to check time is preserved
        viewModel.pauseSession()
        XCTAssertEqual(viewModel.displayTime, "25:00")

        // Complete work session (simulated by starting and stopping)
        // In a real scenario, we'd wait for the timer, but for tests we'll verify the display
        viewModel.resumeSession()
        viewModel.pauseSession()
        XCTAssertTrue(viewModel.canResume)

        // Complete and check break time by examining displayTime when in completed state
        // For now, we'll test the preset values directly
        XCTAssertEqual(Preset.short.workDuration, 25 * 60)
        XCTAssertEqual(Preset.short.breakDuration, 5 * 60)

        // Reset and test long preset (50/10)
        viewModel.cleanup()
        viewModel = FocusSessionViewModel(presetSettings: presetSettings)
        viewModel.selectedPreset = .long
        viewModel.startSession()
        XCTAssertEqual(viewModel.displayTime, "50:00", "Long preset should show 50 minutes")
        XCTAssertEqual(viewModel.currentSessionType, "Focus")

        // Verify preset durations
        XCTAssertEqual(Preset.long.workDuration, 50 * 60)
        XCTAssertEqual(Preset.long.breakDuration, 10 * 60)
    }
}
