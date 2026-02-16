import SwiftUI
import XCTest
@testable import Oak

@MainActor
internal final class AudioPersistenceTests: XCTestCase {
    var viewModel: FocusSessionViewModel!
    var presetSettings: PresetSettingsStore!
    var presetSuiteName: String!

    override func setUp() async throws {
        let suiteName = "AudioPersistenceTests.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            throw NSError(domain: "AudioPersistenceTests", code: 1)
        }
        userDefaults.removePersistentDomain(forName: suiteName)
        presetSuiteName = suiteName
        presetSettings = PresetSettingsStore(userDefaults: userDefaults)
        viewModel = FocusSessionViewModel(
            presetSettings: presetSettings,
            notificationService: NotificationService()
        )
    }

    override func tearDown() async throws {
        viewModel.cleanup()
        if let presetSuiteName {
            UserDefaults(suiteName: presetSuiteName)?.removePersistentDomain(forName: presetSuiteName)
        }
    }

    // MARK: - Audio Track Persistence Tests

    func testAudioTrackPersistsAcrossManualSessionTransition() {
        // Start a focus session
        viewModel.startSession()
        XCTAssertTrue(viewModel.isRunning, "Session should be running")

        // Select and play rain audio
        viewModel.audioManager.play(track: .rain)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain, "Rain should be playing")
        XCTAssertTrue(viewModel.audioManager.isPlaying, "Audio should be playing")

        // Complete the session
        viewModel.completeSession()
        XCTAssertFalse(viewModel.audioManager.isPlaying, "Audio should stop on completion")
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .none, "Selected track should be none after stop")

        // Start next session manually
        viewModel.startNextSession()
        XCTAssertTrue(viewModel.isRunning, "Next session should be running")

        // Audio should resume with rain
        XCTAssertTrue(viewModel.audioManager.isPlaying, "Audio should resume playing")
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain, "Rain should resume playing")
    }

    func testAudioTrackPersistsAcrossAutoStartSessionTransition() async {
        // Enable auto-start
        presetSettings.setAutoStartNextInterval(true)

        // Start a focus session
        viewModel.startSession()
        XCTAssertTrue(viewModel.isRunning, "Session should be running")

        // Select and play forest audio
        viewModel.audioManager.play(track: .forest)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .forest, "Forest should be playing")
        XCTAssertTrue(viewModel.audioManager.isPlaying, "Audio should be playing")

        // Complete the session
        viewModel.completeSession()
        XCTAssertFalse(viewModel.audioManager.isPlaying, "Audio should stop on completion")

        // Wait for auto-start countdown and next session to start
        try? await Task.sleep(nanoseconds: 13_000_000_000) // 13 seconds for auto-start

        // Audio should resume with forest
        XCTAssertTrue(viewModel.isRunning, "Next session should have auto-started")
        XCTAssertTrue(viewModel.audioManager.isPlaying, "Audio should resume playing")
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .forest, "Forest should resume playing")
    }

    func testAudioTrackPersistsThroughMultipleSessions() {
        // Start with rain audio
        viewModel.startSession()
        viewModel.audioManager.play(track: .rain)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain)

        // Complete and start next (break)
        viewModel.completeSession()
        viewModel.startNextSession()
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain, "Rain should persist to break")

        // Complete break and start next focus
        viewModel.completeSession()
        viewModel.startNextSession()
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain, "Rain should persist to next focus")
    }

    func testNoAudioDoesNotStartAutomatically() {
        // Start a session without selecting audio
        viewModel.startSession()
        XCTAssertFalse(viewModel.audioManager.isPlaying, "No audio should be playing")
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .none)

        // Complete and start next
        viewModel.completeSession()
        viewModel.startNextSession()

        // Audio should still be none
        XCTAssertFalse(viewModel.audioManager.isPlaying, "No audio should start automatically")
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .none)
    }

    func testAudioTrackChangeMidSessionPersistsToNext() {
        // Start with rain
        viewModel.startSession()
        viewModel.audioManager.play(track: .rain)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain)

        // Change to cafe mid-session
        viewModel.audioManager.play(track: .cafe)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .cafe)

        // Complete and start next
        viewModel.completeSession()
        viewModel.startNextSession()

        // Cafe should persist (the last playing track)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .cafe, "Cafe should persist as it was last playing")
    }

    func testStoppingAudioMidSessionDoesNotResumeAutomatically() {
        // Start with rain
        viewModel.startSession()
        viewModel.audioManager.play(track: .rain)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain)

        // Stop audio mid-session
        viewModel.audioManager.stop()
        XCTAssertFalse(viewModel.audioManager.isPlaying)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .none)

        // Complete and start next
        viewModel.completeSession()
        viewModel.startNextSession()

        // No audio should start (user stopped it)
        XCTAssertFalse(viewModel.audioManager.isPlaying, "Audio should not resume if user stopped it")
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .none)
    }

    func testAudioTrackClearsOnReset() {
        // Start with rain
        viewModel.startSession()
        viewModel.audioManager.play(track: .rain)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain)

        // Complete session
        viewModel.completeSession()

        // Reset session
        viewModel.resetSession()

        // Start a new session
        viewModel.startSession()

        // No audio should play (reset cleared the memory)
        XCTAssertFalse(viewModel.audioManager.isPlaying, "Audio should not resume after reset")
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .none)
    }

    func testDifferentAudioTracksForDifferentSessionTypes() {
        // Start focus with rain
        viewModel.startSession()
        viewModel.audioManager.play(track: .rain)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain)

        // Complete and start break
        viewModel.completeSession()
        viewModel.startNextSession()
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain, "Rain should continue to break")

        // Change to forest during break
        viewModel.audioManager.play(track: .forest)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .forest)

        // Complete break and start focus
        viewModel.completeSession()
        viewModel.startNextSession()

        // Forest should persist (last playing track)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .forest, "Forest should persist to focus")
    }

    func testAudioVolumeIsPreservedAcrossSessions() {
        // Set volume to 0.7
        viewModel.audioManager.setVolume(0.7)
        XCTAssertEqual(viewModel.audioManager.volume, 0.7)

        // Start session with rain
        viewModel.startSession()
        viewModel.audioManager.play(track: .rain)

        // Complete and start next
        viewModel.completeSession()
        viewModel.startNextSession()

        // Volume should be preserved
        XCTAssertEqual(viewModel.audioManager.volume, 0.7, "Volume should be preserved")
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain, "Rain should resume")
    }

    func testAudioPersistsWithLongBreak() {
        // Start with brown noise
        viewModel.startSession()
        viewModel.audioManager.play(track: .brownNoise)

        // Complete 4 work sessions to trigger long break
        for _ in 0 ..< 4 {
            viewModel.completeSession()
            viewModel.startNextSession()
            // Verify audio persists
            XCTAssertEqual(viewModel.audioManager.selectedTrack, .brownNoise)
            if viewModel.currentSessionType != "Long Break" {
                viewModel.completeSession()
                viewModel.startNextSession()
            }
        }

        // Should still have brown noise in long break
        XCTAssertEqual(viewModel.currentSessionType, "Long Break")
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .brownNoise, "Brown noise should persist to long break")
    }
}
