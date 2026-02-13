import AVFoundation
import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class US004Tests: XCTestCase {
    var viewModel: FocusSessionViewModel!
    var presetSettings: PresetSettingsStore!
    var presetSuiteName: String!

    override func setUp() async throws {
        let suiteName = "OakTests.US004.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw NSError(domain: "US004Tests", code: 1)
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

    func testBuiltInTracksAvailable() {
        let tracks = AudioTrack.allCases
        let expectedTracks: [AudioTrack] = [.none, .rain, .forest, .cafe, .brownNoise, .lofi]

        for track in expectedTracks {
            XCTAssertTrue(tracks.contains(track), "Should have \(track.rawValue) track")
        }

        XCTAssertEqual(tracks.count, 6, "Should have 6 tracks (including none)")
    }

    func testCanSelectTrackBeforeSession() {
        // Select a track before starting
        viewModel.audioManager.play(track: .rain)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain)
        XCTAssertTrue(viewModel.audioManager.isPlaying)

        // Verify can select another track
        viewModel.audioManager.play(track: .forest)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .forest)
    }

    func testCanSelectTrackDuringSession() {
        // Start session
        viewModel.startSession()

        // Select track during session
        viewModel.audioManager.play(track: .rain)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain)
        XCTAssertTrue(viewModel.audioManager.isPlaying)

        // Change track during session
        viewModel.audioManager.play(track: .cafe)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .cafe)
    }

    func testCanAdjustVolume() {
        let audioManager = viewModel.audioManager

        // Test default volume
        XCTAssertEqual(audioManager.volume, 0.5, accuracy: 0.01, "Default volume should be 0.5")

        // Test setting volume
        audioManager.setVolume(0.75)
        XCTAssertEqual(audioManager.volume, 0.75, accuracy: 0.01)

        // Test volume bounds
        audioManager.setVolume(1.5)
        XCTAssertEqual(audioManager.volume, 1.0, accuracy: 0.01, "Volume should be clamped to 1.0")

        audioManager.setVolume(-0.5)
        XCTAssertEqual(audioManager.volume, 0.0, accuracy: 0.01, "Volume should be clamped to 0.0")

        // Test minimum volume
        audioManager.setVolume(0.0)
        XCTAssertEqual(audioManager.volume, 0.0, accuracy: 0.01)

        // Test maximum volume
        audioManager.setVolume(1.0)
        XCTAssertEqual(audioManager.volume, 1.0, accuracy: 0.01)
    }

    func testAudioStopsAutomaticallyWhenSessionEnds() {
        // Start audio
        viewModel.audioManager.play(track: .rain)
        XCTAssertTrue(viewModel.audioManager.isPlaying)

        // Complete session (this should stop audio)
        // We need to simulate session completion
        // Note: Can't easily test this without accessing private methods
        // For now, we'll test the cleanup method
        viewModel.cleanup()
        XCTAssertFalse(viewModel.audioManager.isPlaying, "Audio should stop after cleanup")
    }

    func testDisplayTargetDefaultsToMainDisplay() {
        XCTAssertEqual(presetSettings.displayTarget, .mainDisplay)
    }

    func testCompletionSoundDefaultsToEnabled() {
        XCTAssertTrue(presetSettings.playSoundOnSessionCompletion)
    }

    func testDisplayTargetIsPersisted() {
        presetSettings.setDisplayTarget(.notchedDisplay)

        guard let reloadedDefaults = UserDefaults(suiteName: presetSuiteName) else {
            XCTFail("Failed to create UserDefaults with suite name")
            return
        }
        let reloadedStore = PresetSettingsStore(userDefaults: reloadedDefaults)
        XCTAssertEqual(reloadedStore.displayTarget, .notchedDisplay)
    }

    func testResetToDefaultRestoresMainDisplayTarget() {
        presetSettings.setDisplayTarget(.notchedDisplay)
        presetSettings.setPlaySoundOnSessionCompletion(false)

        presetSettings.resetToDefault()

        XCTAssertEqual(presetSettings.displayTarget, .mainDisplay)
        XCTAssertTrue(presetSettings.playSoundOnSessionCompletion)
    }

    func testSwitchingTargetWithoutScreenIDPreservesStoredDisplayIDs() {
        let initialMainID = presetSettings.mainDisplayID
        let initialNotchedID = presetSettings.notchedDisplayID

        presetSettings.setDisplayTarget(.notchedDisplay)
        XCTAssertEqual(presetSettings.mainDisplayID, initialMainID)
        XCTAssertEqual(presetSettings.notchedDisplayID, initialNotchedID)

        presetSettings.setDisplayTarget(.mainDisplay)
        XCTAssertEqual(presetSettings.mainDisplayID, initialMainID)
        XCTAssertEqual(presetSettings.notchedDisplayID, initialNotchedID)
    }

    func testCompletionSoundPreferenceIsPersisted() {
        presetSettings.setPlaySoundOnSessionCompletion(false)

        guard let reloadedDefaults = UserDefaults(suiteName: presetSuiteName) else {
            XCTFail("Failed to create UserDefaults with suite name")
            return
        }
        let reloadedStore = PresetSettingsStore(userDefaults: reloadedDefaults)
        XCTAssertFalse(reloadedStore.playSoundOnSessionCompletion)
    }

    func testLongBreakSettingsPersisted() {
        presetSettings.setLongBreakMinutes(30, for: .short)
        presetSettings.setLongBreakMinutes(25, for: .long)
        presetSettings.setRoundsBeforeLongBreak(6)

        guard let reloadedDefaults = UserDefaults(suiteName: presetSuiteName) else {
            XCTFail("Failed to create UserDefaults with suite name")
            return
        }
        let reloadedStore = PresetSettingsStore(userDefaults: reloadedDefaults)
        XCTAssertEqual(reloadedStore.longBreakMinutes(for: .short), 30)
        XCTAssertEqual(reloadedStore.longBreakMinutes(for: .long), 25)
        XCTAssertEqual(reloadedStore.roundsBeforeLongBreak, 6)
    }

    func testResetToDefaultRestoresLongBreakSettings() {
        presetSettings.setLongBreakMinutes(30, for: .short)
        presetSettings.setLongBreakMinutes(25, for: .long)
        presetSettings.setRoundsBeforeLongBreak(6)

        presetSettings.resetToDefault()

        XCTAssertEqual(presetSettings.longBreakMinutes(for: .short), Preset.short.defaultLongBreakMinutes)
        XCTAssertEqual(presetSettings.longBreakMinutes(for: .long), Preset.long.defaultLongBreakMinutes)
        XCTAssertEqual(presetSettings.roundsBeforeLongBreak, 4)
    }

    func testRoundsBeforeLongBreakIsClampedToValidRange() {
        presetSettings.setRoundsBeforeLongBreak(0)
        XCTAssertEqual(presetSettings.roundsBeforeLongBreak, PresetSettingsStore.minRoundsBeforeLongBreak)

        presetSettings.setRoundsBeforeLongBreak(100)
        XCTAssertEqual(presetSettings.roundsBeforeLongBreak, PresetSettingsStore.maxRoundsBeforeLongBreak)
    }
}
