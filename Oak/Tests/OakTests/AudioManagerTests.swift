import AVFoundation
import XCTest
@testable import Oak

// MARK: - MockAudioEngine

internal final class MockAudioEngine: AudioEngineProtocol {
    var isRunning: Bool = false
    var outputChannelCount: AVAudioChannelCount = 2
    var outputSampleRate: Double = 44100
    var startError: Error?
    var mixerVolume: Float = 1.0
    var prepareCalled = false
    var startCalled = false
    var stopCalled = false
    var pauseCalled = false
    var attachedNodes: [AVAudioNode] = []
    var detachedNodes: [AVAudioNode] = []

    func setMixerVolume(_ volume: Float) { mixerVolume = volume }

    func attachAndConnect(_ node: AVAudioNode) {
        attachedNodes.append(node)
    }

    func detach(_ node: AVAudioNode) {
        detachedNodes.append(node)
    }

    func prepare() { prepareCalled = true }

    func start() throws {
        if let error = startError { throw error }
        isRunning = true
        startCalled = true
    }

    func stop() {
        isRunning = false
        stopCalled = true
    }

    func pause() {
        isRunning = false
        pauseCalled = true
    }
}

// MARK: - NoiseGeneratorTests

@MainActor
internal final class NoiseGeneratorTests: XCTestCase {
    func testBrownNoiseOutputWithinRange() {
        let generator = NoiseGenerator()
        for _ in 0 ..< 1000 {
            let sample = generator.generateBrownNoise()
            XCTAssertGreaterThanOrEqual(sample, -0.15, "Brown noise must be >= -0.15")
            XCTAssertLessThanOrEqual(sample, 0.15, "Brown noise must be <= 0.15")
        }
    }

    func testRainNoiseOutputWithinRange() {
        let generator = NoiseGenerator()
        for _ in 0 ..< 1000 {
            let sample = generator.generateRainNoise()
            XCTAssertGreaterThanOrEqual(sample, -0.3, "Rain noise must be >= -0.3")
            XCTAssertLessThanOrEqual(sample, 0.3, "Rain noise must be <= 0.3")
        }
    }

    func testForestNoiseOutputWithinRange() {
        let generator = NoiseGenerator()
        for _ in 0 ..< 1000 {
            let sample = generator.generateForestNoise()
            XCTAssertGreaterThanOrEqual(sample, -0.35, "Forest noise must be >= -0.35")
            XCTAssertLessThanOrEqual(sample, 0.35, "Forest noise must be <= 0.35")
        }
    }

    func testCafeNoiseOutputWithinRange() {
        let generator = NoiseGenerator()
        for _ in 0 ..< 1000 {
            let sample = generator.generateCafeNoise()
            XCTAssertGreaterThanOrEqual(sample, -0.35, "Cafe noise must be >= -0.35")
            XCTAssertLessThanOrEqual(sample, 0.35, "Cafe noise must be <= 0.35")
        }
    }

    func testLofiNoiseOutputWithinRange() {
        let generator = NoiseGenerator()
        for _ in 0 ..< 1000 {
            let sample = generator.generateLofiNoise()
            XCTAssertGreaterThanOrEqual(sample, -0.30, "Lo-Fi noise must be >= -0.30")
            XCTAssertLessThanOrEqual(sample, 0.30, "Lo-Fi noise must be <= 0.30")
        }
    }

    func testBrownNoiseAccumulatesState() {
        let generator = NoiseGenerator()
        let samples = (0 ..< 100).map { _ in generator.generateBrownNoise() }
        let hasMagnitude = samples.contains { abs($0) > 0 }
        XCTAssertTrue(hasMagnitude, "Brown noise should produce non-zero values over time")
    }

    func testRainNoiseSeedWraps() {
        let generator = NoiseGenerator()
        // maxSeed = Float.pi * 2000 ≈ 6283; step = 0.01 per call → ~628,320 calls to wrap.
        // Run past the wrap point to verify the modulo prevents unbounded growth.
        for _ in 0 ..< 700_000 {
            _ = generator.generateRainNoise()
        }
        let sample = generator.generateRainNoise()
        XCTAssertGreaterThanOrEqual(sample, -0.3)
        XCTAssertLessThanOrEqual(sample, 0.3)
    }
}

// MARK: - AudioManagerTests

@MainActor
internal final class AudioManagerTests: XCTestCase {
    var manager: AudioManager!

    override func setUp() async throws {
        manager = AudioManager()
    }

    override func tearDown() async throws {
        manager.stop()
        manager = nil
    }

    // MARK: - Volume Control

    func testDefaultVolumeIsHalf() {
        XCTAssertEqual(manager.volume, 0.5, accuracy: 0.001)
    }

    func testSetVolumeWithinBounds() {
        manager.setVolume(0.75)
        XCTAssertEqual(manager.volume, 0.75, accuracy: 0.001)
    }

    func testSetVolumeClampsAboveOne() {
        manager.setVolume(1.5)
        XCTAssertEqual(manager.volume, 1.0, accuracy: 0.001)
    }

    func testSetVolumeClampsAtZero() {
        manager.setVolume(-0.5)
        XCTAssertEqual(manager.volume, 0.0, accuracy: 0.001)
    }

    // MARK: - Track Selection

    func testPlayNoneStopsPlayback() {
        manager.play(track: .brownNoise)
        manager.play(track: .none)
        XCTAssertFalse(manager.isPlaying)
        XCTAssertEqual(manager.selectedTrack, .none)
    }

    func testPlayAmbientTrackSetsIsPlaying() {
        manager.play(track: .brownNoise)
        XCTAssertTrue(manager.isPlaying)
    }

    func testPlayAmbientTrackSetsSelectedTrack() {
        manager.play(track: .rain)
        XCTAssertEqual(manager.selectedTrack, .rain)
    }

    func testPlayDifferentTrackUpdatesSelectedTrack() {
        manager.play(track: .brownNoise)
        manager.play(track: .forest)
        XCTAssertEqual(manager.selectedTrack, .forest)
    }

    // MARK: - Stop

    func testStopClearsIsPlaying() {
        manager.play(track: .brownNoise)
        manager.stop()
        XCTAssertFalse(manager.isPlaying)
    }

    func testStopClearsSelectedTrack() {
        manager.play(track: .brownNoise)
        manager.stop()
        XCTAssertEqual(manager.selectedTrack, .none)
    }

    // MARK: - Pause / Resume

    func testPauseSetsIsPlayingFalse() {
        manager.play(track: .brownNoise)
        manager.pause()
        XCTAssertFalse(manager.isPlaying)
    }

    func testPausePreservesSelectedTrack() {
        manager.play(track: .brownNoise)
        manager.pause()
        XCTAssertEqual(manager.selectedTrack, .brownNoise)
    }

    func testResumeAfterPauseSetsIsPlayingTrue() {
        manager.play(track: .brownNoise)
        manager.pause()
        manager.resume()
        XCTAssertTrue(manager.isPlaying)
    }

    func testResumeWhenNotPlayingDoesNothing() {
        manager.resume()
        XCTAssertFalse(manager.isPlaying)
    }

    // MARK: - All Tracks

    func testAllAmbientTracksCanBePlayed() {
        let ambientTracks: [AudioTrack] = [.brownNoise, .rain, .forest, .cafe, .lofi]
        for track in ambientTracks {
            manager.stop()
            manager.play(track: track)
            XCTAssertTrue(manager.isPlaying, "\(track.rawValue) should be playing")
            XCTAssertEqual(manager.selectedTrack, track)
        }
    }
}
