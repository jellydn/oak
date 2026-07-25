import XCTest
@testable import Oak

internal final class SmokeTests: XCTestCase {
    func testTrue() {
        XCTAssertTrue(true)
    }

    // MARK: - App Target Import

    func testAppTargetCanBeImported() {
        _ = SessionState.self
        _ = Preset.self
        _ = DisplayTarget.self
        _ = AudioTrack.self
        _ = CountdownDisplayMode.self
        _ = NotchLayout.self
    }

    func testAllServiceTypesExist() {
        _ = AudioManager.self
        _ = NotificationService.self
        _ = PresetSettingsStore.self
        _ = Oak.ProgressManager.self
        _ = SparkleUpdater.self
    }

    func testAllViewModelTypesExist() {
        _ = FocusSessionViewModel.self
    }

    // MARK: - Preset Defaults

    func testShortPresetWorkMinutes() {
        XCTAssertEqual(Preset.short.defaultWorkMinutes, 25)
    }

    func testShortPresetBreakMinutes() {
        XCTAssertEqual(Preset.short.defaultBreakMinutes, 5)
    }

    func testShortPresetLongBreakMinutes() {
        XCTAssertEqual(Preset.short.defaultLongBreakMinutes, 15)
    }

    func testLongPresetWorkMinutes() {
        XCTAssertEqual(Preset.long.defaultWorkMinutes, 50)
    }

    func testLongPresetBreakMinutes() {
        XCTAssertEqual(Preset.long.defaultBreakMinutes, 10)
    }

    func testLongPresetLongBreakMinutes() {
        XCTAssertEqual(Preset.long.defaultLongBreakMinutes, 20)
    }

    func testShortPresetDisplayName() {
        XCTAssertEqual(Preset.short.displayName, "25/5")
    }

    func testLongPresetDisplayName() {
        XCTAssertEqual(Preset.long.displayName, "50/10")
    }

    // MARK: - Session State

    func testSessionStateIdleIsEquatable() {
        XCTAssertEqual(SessionState.idle, SessionState.idle)
    }

    func testSessionStateRunningIsEquatable() {
        let first = SessionState.running(remainingSeconds: 1500, isWorkSession: true)
        let second = SessionState.running(remainingSeconds: 1500, isWorkSession: true)
        XCTAssertEqual(first, second)
    }

    func testSessionStateRunningDiffersBySeconds() {
        let first = SessionState.running(remainingSeconds: 1500, isWorkSession: true)
        let second = SessionState.running(remainingSeconds: 1400, isWorkSession: true)
        XCTAssertNotEqual(first, second)
    }

    func testSessionStatePausedIsEquatable() {
        let first = SessionState.paused(remainingSeconds: 300, isWorkSession: false)
        let second = SessionState.paused(remainingSeconds: 300, isWorkSession: false)
        XCTAssertEqual(first, second)
    }

    func testSessionStateCompletedIsEquatable() {
        let first = SessionState.completed(isWorkSession: true)
        let second = SessionState.completed(isWorkSession: true)
        XCTAssertEqual(first, second)
    }

    // MARK: - Audio Tracks

    func testAudioTrackHasAllCases() {
        let allCases = AudioTrack.allCases
        XCTAssertEqual(allCases.count, 6)
    }

    func testAudioTrackContainsExpectedTracks() {
        let cases = AudioTrack.allCases.map(\.rawValue)
        XCTAssertTrue(cases.contains("None"))
        XCTAssertTrue(cases.contains("Rain"))
        XCTAssertTrue(cases.contains("Forest"))
        XCTAssertTrue(cases.contains("Cafe"))
        XCTAssertTrue(cases.contains("Brown Noise"))
        XCTAssertTrue(cases.contains("Lo-Fi"))
    }

    func testAudioTrackNoneHasIcon() {
        XCTAssertFalse(AudioTrack.none.systemImageName.isEmpty)
    }

    func testAudioTrackIconNamesAreUnique() {
        let icons = AudioTrack.allCases.map(\.systemImageName)
        let uniqueIcons = Set(icons)
        XCTAssertEqual(icons.count, uniqueIcons.count, "All audio track icons should be unique")
    }

    // MARK: - Display Target

    func testDisplayTargetHasBothCases() {
        let allCases = DisplayTarget.allCases
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.mainDisplay))
        XCTAssertTrue(allCases.contains(.notchedDisplay))
    }

    func testDisplayTargetDisplayNamesAreNonEmpty() {
        XCTAssertFalse(DisplayTarget.mainDisplay.displayName.isEmpty)
        XCTAssertFalse(DisplayTarget.notchedDisplay.displayName.isEmpty)
    }

    // MARK: - Countdown Display Mode

    func testCountdownDisplayModeHasBothCases() {
        let allCases = CountdownDisplayMode.allCases
        XCTAssertTrue(allCases.contains(.number))
        XCTAssertTrue(allCases.contains(.circleRing))
    }

    // MARK: - NotchLayout

    func testNotchLayoutDimensionsArePositive() {
        XCTAssertGreaterThan(NotchLayout.height, 0)
        XCTAssertGreaterThan(NotchLayout.collapsedWidth, 0)
        XCTAssertGreaterThan(NotchLayout.expandedWidth, 0)
    }
}
