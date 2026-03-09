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
        var hasMagnitude = false
        for _ in 0 ..< 100 {
            if abs(generator.generateBrownNoise()) > 0 {
                hasMagnitude = true
                break
            }
        }
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
    var mockEngine: MockAudioEngine!
    var manager: AudioManager!

    override func setUp() async throws {
        let mock = MockAudioEngine()
        mockEngine = mock
        manager = AudioManager { mock }
    }

    override func tearDown() async throws {
        manager.stop()
        manager = nil
        mockEngine = nil
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

    func testSetVolumeUpdatesEngineVolumeWhilePlaying() {
        manager.play(track: .brownNoise)
        manager.setVolume(0.8)
        XCTAssertEqual(mockEngine.mixerVolume, 0.8, accuracy: 0.001)
    }

    // MARK: - Track Selection

    func testPlayNoneStopsPlayback() {
        manager.play(track: .brownNoise)
        XCTAssertTrue(manager.isPlaying)

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

    // MARK: - Engine Lifecycle

    func testPlayStartsEngine() {
        manager.play(track: .brownNoise)
        XCTAssertTrue(mockEngine.startCalled)
        XCTAssertTrue(mockEngine.isRunning)
    }

    func testPlayPreparesEngineOnFirstUse() {
        manager.play(track: .brownNoise)
        XCTAssertTrue(mockEngine.prepareCalled)
    }

    func testPlayDoesNotPrepareEngineOnReuse() {
        manager.play(track: .brownNoise)
        mockEngine.prepareCalled = false

        manager.play(track: .rain)
        XCTAssertFalse(mockEngine.prepareCalled)
    }

    func testPlayAttachesSourceNode() {
        manager.play(track: .brownNoise)
        XCTAssertEqual(mockEngine.attachedNodes.count, 1)
    }

    func testPlayEngineStartFailureDoesNotSetIsPlaying() {
        mockEngine.startError = NSError(domain: "AudioTest", code: -1, userInfo: nil)
        manager.play(track: .brownNoise)
        XCTAssertFalse(manager.isPlaying)
    }

    func testPlayEngineStartFailureDoesNotSetSelectedTrack() {
        mockEngine.startError = NSError(domain: "AudioTest", code: -1, userInfo: nil)
        manager.play(track: .brownNoise)
        XCTAssertEqual(manager.selectedTrack, .none)
    }

    func testPlayWithInvalidOutputFormatDoesNotSetIsPlaying() {
        mockEngine.outputChannelCount = 0
        manager.play(track: .brownNoise)
        XCTAssertFalse(manager.isPlaying)
    }

    func testInvalidOutputFormatDoesNotSetTrack() {
        mockEngine.outputChannelCount = 0
        manager.play(track: .brownNoise)
        XCTAssertEqual(manager.selectedTrack, .none)
    }

    func testPlayWithZeroSampleRateDoesNotSetIsPlaying() {
        mockEngine.outputSampleRate = 0
        manager.play(track: .brownNoise)
        XCTAssertFalse(manager.isPlaying)
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

    func testStopCallsEngineStop() {
        manager.play(track: .brownNoise)
        manager.stop()
        XCTAssertTrue(mockEngine.stopCalled)
    }

    func testStopDetachesSourceNodes() {
        manager.play(track: .brownNoise)
        let attached = mockEngine.attachedNodes
        manager.stop()
        XCTAssertFalse(attached.isEmpty, "Should have attached a node before stop")
        XCTAssertEqual(mockEngine.detachedNodes.count, attached.count)
    }

    // MARK: - Pause / Resume

    func testPauseSetsIsPlayingFalse() {
        manager.play(track: .brownNoise)
        manager.pause()
        XCTAssertFalse(manager.isPlaying)
    }

    func testPauseCallsEnginePause() {
        manager.play(track: .brownNoise)
        manager.pause()
        XCTAssertTrue(mockEngine.pauseCalled)
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
        // No track selected, no engine
        manager.resume()
        XCTAssertFalse(manager.isPlaying)
    }

    // MARK: - Missing Bundled Track Fallback

    func testMissingBundledTrackFallsBackToGeneratedNoise() {
        // In the test bundle, no ambient audio files exist.
        // play() should fall back to generateAmbientSound, which uses the mock engine.
        manager.play(track: .cafe)
        XCTAssertTrue(manager.isPlaying, "Should fall back to generated noise when bundled file is missing")
        XCTAssertEqual(manager.selectedTrack, .cafe)
    }

    func testAllAmbientTracksCanBePlayed() {
        let ambientTracks: [AudioTrack] = [.brownNoise, .rain, .forest, .cafe, .lofi]
        for track in ambientTracks {
            manager.stop()
            mockEngine.startCalled = false
            mockEngine.isRunning = false
            manager.play(track: track)
            XCTAssertTrue(manager.isPlaying, "\(track.rawValue) should be playing")
            XCTAssertEqual(manager.selectedTrack, track)
        }
    }
}
