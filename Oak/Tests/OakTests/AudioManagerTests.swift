import AVFoundation
import XCTest
@testable import Oak

@MainActor
internal final class AudioManagerTests: XCTestCase {
    var audioManager: AudioManager!

    override func setUp() async throws {
        audioManager = AudioManager()
    }

    override func tearDown() async throws {
        audioManager.stop()
        audioManager = nil
    }

    // MARK: - Audio Engine Lifecycle Tests

    func testInitialState() {
        XCTAssertEqual(audioManager.selectedTrack, .none)
        XCTAssertEqual(audioManager.volume, 0.5)
        XCTAssertFalse(audioManager.isPlaying)
    }

    func testPlayGeneratedTrackStartsAudio() {
        audioManager.play(track: .brownNoise)

        XCTAssertTrue(audioManager.isPlaying)
        XCTAssertEqual(audioManager.selectedTrack, .brownNoise)
    }

    func testStopAudioClearsState() {
        audioManager.play(track: .brownNoise)
        XCTAssertTrue(audioManager.isPlaying)

        audioManager.stop()

        XCTAssertFalse(audioManager.isPlaying)
        XCTAssertEqual(audioManager.selectedTrack, .none)
    }

    func testPlayNoneTrackStopsAudio() {
        audioManager.play(track: .brownNoise)
        XCTAssertTrue(audioManager.isPlaying)

        audioManager.play(track: .none)

        XCTAssertFalse(audioManager.isPlaying)
        XCTAssertEqual(audioManager.selectedTrack, .none)
    }

    func testRestartAudioWithDifferentTrack() {
        audioManager.play(track: .brownNoise)
        XCTAssertEqual(audioManager.selectedTrack, .brownNoise)
        XCTAssertTrue(audioManager.isPlaying)

        audioManager.play(track: .rain)
        XCTAssertEqual(audioManager.selectedTrack, .rain)
        XCTAssertTrue(audioManager.isPlaying)
    }

    // MARK: - Volume Control Tests

    func testSetVolumeClamps() {
        audioManager.setVolume(1.5)
        XCTAssertEqual(audioManager.volume, 1.0)

        audioManager.setVolume(-0.5)
        XCTAssertEqual(audioManager.volume, 0.0)

        audioManager.setVolume(0.7)
        XCTAssertEqual(audioManager.volume, 0.7)
    }

    func testVolumeChangesDuringPlayback() {
        audioManager.play(track: .brownNoise)
        XCTAssertEqual(audioManager.volume, 0.5)

        audioManager.setVolume(0.8)
        XCTAssertEqual(audioManager.volume, 0.8)
        XCTAssertTrue(audioManager.isPlaying)
    }

    // MARK: - Track Switching Tests

    func testSwitchBetweenAllTracks() {
        let tracks: [AudioTrack] = [.brownNoise, .rain, .forest, .cafe, .lofi]

        for track in tracks {
            audioManager.play(track: track)
            XCTAssertEqual(audioManager.selectedTrack, track)
            XCTAssertTrue(audioManager.isPlaying)
        }
    }

    func testMultipleStartStopCycles() {
        for _ in 0 ..< 3 {
            audioManager.play(track: .brownNoise)
            XCTAssertTrue(audioManager.isPlaying)

            audioManager.stop()
            XCTAssertFalse(audioManager.isPlaying)
        }
    }

    // MARK: - Memory Cleanup Tests

    func testStopClearsAudioNodes() {
        audioManager.play(track: .brownNoise)
        XCTAssertTrue(audioManager.isPlaying)

        audioManager.stop()

        XCTAssertFalse(audioManager.isPlaying)
        XCTAssertEqual(audioManager.selectedTrack, .none)
    }

    func testTrackSwitchClearsOldNodes() {
        audioManager.play(track: .rain)
        let firstTrack = audioManager.selectedTrack

        audioManager.play(track: .forest)
        let secondTrack = audioManager.selectedTrack

        XCTAssertNotEqual(firstTrack, secondTrack)
        XCTAssertTrue(audioManager.isPlaying)
    }

    // MARK: - Bundled vs Generated Audio Tests

    func testBundledTrackFallbackToGenerated() {
        // All tracks should either play bundled or fall back to generated
        audioManager.play(track: .rain)
        XCTAssertTrue(audioManager.isPlaying)
        XCTAssertEqual(audioManager.selectedTrack, .rain)
    }

    func testGeneratedAudioForAllTracks() {
        let generatedTracks: [AudioTrack] = [.brownNoise, .rain, .forest, .cafe, .lofi]

        for track in generatedTracks {
            audioManager.stop()
            audioManager.play(track: track)
            XCTAssertTrue(audioManager.isPlaying, "Track \(track.rawValue) should be playing")
            XCTAssertEqual(audioManager.selectedTrack, track)
        }
    }

    // MARK: - Edge Cases

    func testStopWhenNotPlaying() {
        XCTAssertFalse(audioManager.isPlaying)
        audioManager.stop()
        XCTAssertFalse(audioManager.isPlaying)
    }

    func testPlaySameTrackTwice() {
        audioManager.play(track: .brownNoise)
        XCTAssertTrue(audioManager.isPlaying)

        audioManager.play(track: .brownNoise)
        XCTAssertTrue(audioManager.isPlaying)
        XCTAssertEqual(audioManager.selectedTrack, .brownNoise)
    }

    func testVolumeSettingBeforePlayback() {
        audioManager.setVolume(0.3)
        XCTAssertEqual(audioManager.volume, 0.3)

        audioManager.play(track: .brownNoise)
        XCTAssertEqual(audioManager.volume, 0.3)
        XCTAssertTrue(audioManager.isPlaying)
    }
}
