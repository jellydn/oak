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
        viewModel.startSession()
        XCTAssertTrue(viewModel.isRunning)

        viewModel.audioManager.play(track: .rain)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain)
        XCTAssertTrue(viewModel.audioManager.isPlaying)

        viewModel.completeSession()
        XCTAssertFalse(viewModel.audioManager.isPlaying)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .none)

        viewModel.startNextSession()
        XCTAssertTrue(viewModel.isRunning)
        XCTAssertEqual(viewModel.currentSessionType, "Break")

        XCTAssertFalse(viewModel.audioManager.isPlaying)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .none)

        viewModel.completeSession()
        viewModel.startNextSession()
        XCTAssertEqual(viewModel.currentSessionType, "Focus")

        XCTAssertTrue(viewModel.audioManager.isPlaying)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain)
    }

    func testAudioTrackPersistsAcrossAutoStartSessionTransition() async {
        presetSettings.setAutoStartNextInterval(true)

        viewModel.startSession()
        XCTAssertTrue(viewModel.isRunning)

        viewModel.audioManager.play(track: .forest)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .forest)
        XCTAssertTrue(viewModel.audioManager.isPlaying)

        viewModel.completeSession()
        XCTAssertFalse(viewModel.audioManager.isPlaying)

        try? await Task.sleep(nanoseconds: 13000000000)

        XCTAssertTrue(viewModel.isRunning)
        XCTAssertEqual(viewModel.currentSessionType, "Break")

        XCTAssertFalse(viewModel.audioManager.isPlaying)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .none)
    }

    func testAudioTrackPersistsThroughMultipleSessions() {
        viewModel.startSession()
        viewModel.audioManager.play(track: .rain)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain)

        viewModel.completeSession()
        viewModel.startNextSession()
        XCTAssertEqual(viewModel.currentSessionType, "Break")
        XCTAssertFalse(viewModel.audioManager.isPlaying)

        viewModel.completeSession()
        viewModel.startNextSession()
        XCTAssertEqual(viewModel.currentSessionType, "Focus")
        XCTAssertTrue(viewModel.audioManager.isPlaying)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain)
    }

    func testNoAudioDoesNotStartAutomatically() {
        viewModel.startSession()
        XCTAssertFalse(viewModel.audioManager.isPlaying)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .none)

        viewModel.completeSession()
        viewModel.startNextSession()

        XCTAssertFalse(viewModel.audioManager.isPlaying)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .none)
    }

    func testAudioTrackChangeMidSessionPersistsToNext() {
        viewModel.startSession()
        viewModel.audioManager.play(track: .rain)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain)

        viewModel.audioManager.play(track: .cafe)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .cafe)

        viewModel.completeSession()
        viewModel.startNextSession()
        XCTAssertFalse(viewModel.audioManager.isPlaying)

        viewModel.completeSession()
        viewModel.startNextSession()

        XCTAssertTrue(viewModel.audioManager.isPlaying)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .cafe)
    }

    func testStoppingAudioMidSessionDoesNotResumeAutomatically() {
        viewModel.startSession()
        viewModel.audioManager.play(track: .rain)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain)

        viewModel.audioManager.stop()
        XCTAssertFalse(viewModel.audioManager.isPlaying)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .none)

        viewModel.completeSession()
        viewModel.startNextSession()

        XCTAssertFalse(viewModel.audioManager.isPlaying)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .none)
    }

    func testAudioTrackClearsOnReset() {
        viewModel.startSession()
        viewModel.audioManager.play(track: .rain)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain)

        viewModel.completeSession()
        viewModel.resetSession()
        viewModel.startSession()

        XCTAssertFalse(viewModel.audioManager.isPlaying)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .none)
    }

    func testDifferentAudioTracksForDifferentSessionTypes() {
        viewModel.startSession()
        viewModel.audioManager.play(track: .rain)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain)

        viewModel.completeSession()
        viewModel.startNextSession()
        XCTAssertFalse(viewModel.audioManager.isPlaying)

        viewModel.audioManager.play(track: .forest)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .forest)

        viewModel.completeSession()
        viewModel.startNextSession()

        XCTAssertTrue(viewModel.audioManager.isPlaying)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .forest)
    }

    func testAudioVolumeIsPreservedAcrossSessions() {
        viewModel.audioManager.setVolume(0.7)
        XCTAssertEqual(viewModel.audioManager.volume, 0.7)

        viewModel.startSession()
        viewModel.audioManager.play(track: .rain)

        viewModel.completeSession()
        viewModel.startNextSession()
        XCTAssertFalse(viewModel.audioManager.isPlaying)

        viewModel.completeSession()
        viewModel.startNextSession()

        XCTAssertEqual(viewModel.audioManager.volume, 0.7)
        XCTAssertTrue(viewModel.audioManager.isPlaying)
        XCTAssertEqual(viewModel.audioManager.selectedTrack, .rain)
    }

    func testAudioPersistsWithLongBreak() {
        viewModel.startSession()
        viewModel.audioManager.play(track: .brownNoise)

        var sessionCount = 0
        while sessionCount < 10 {
            viewModel.completeSession()
            viewModel.startNextSession()
            sessionCount += 1

            if viewModel.currentSessionType == "Long Break" {
                XCTAssertFalse(viewModel.audioManager.isPlaying)
                break
            } else {
                XCTAssertFalse(viewModel.audioManager.isPlaying)

                viewModel.completeSession()
                viewModel.startNextSession()
                sessionCount += 1

                XCTAssertEqual(viewModel.currentSessionType, "Focus")
                XCTAssertTrue(viewModel.audioManager.isPlaying)
                XCTAssertEqual(viewModel.audioManager.selectedTrack, .brownNoise)
            }
        }

        XCTAssertEqual(viewModel.currentSessionType, "Long Break")
    }
}
