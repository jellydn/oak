import AVFoundation
import XCTest
@testable import Oak

@MainActor
internal final class AmbientAudioPlaybackTests: XCTestCase {
    private var engine: MockAmbientAudioEngine!
    private var playback: AmbientAudioPlayback!

    override func setUp() async throws {
        engine = MockAmbientAudioEngine()
        playback = AmbientAudioPlayback { [engine] in engine! }
    }

    override func tearDown() async throws {
        playback.stop()
        playback = nil
        engine = nil
    }

    func testPlayConfiguresAndStartsEngine() {
        XCTAssertTrue(playback.play(track: .rain, volume: 0.75))
        XCTAssertTrue(engine.isRunning)
        XCTAssertTrue(engine.prepareCalled)
        XCTAssertTrue(engine.startCalled)
        XCTAssertEqual(engine.mixerVolume, 0.75, accuracy: 0.001)
        XCTAssertEqual(engine.attachedNodes.count, 1)
    }

    func testPauseAndResumePreserveConfiguredSource() {
        XCTAssertTrue(playback.play(track: .brownNoise, volume: 0.5))

        playback.pause()
        XCTAssertTrue(engine.pauseCalled)
        XCTAssertFalse(engine.isRunning)

        XCTAssertTrue(playback.resume())
        XCTAssertTrue(engine.startCalled)
        XCTAssertTrue(engine.isRunning)
    }

    func testStopDetachesSourcesAndStopsEngine() {
        XCTAssertTrue(playback.play(track: .forest, volume: 0.5))

        playback.stop()

        XCTAssertTrue(engine.stopCalled)
        XCTAssertEqual(engine.detachedNodes.count, 1)
        XCTAssertFalse(engine.isRunning)
    }

    func testPlaybackRejectsUnavailableOutputFormat() {
        engine.outputChannelCount = 0

        XCTAssertFalse(playback.play(track: .cafe, volume: 0.5))
        XCTAssertTrue(engine.stopCalled)
        XCTAssertTrue(engine.attachedNodes.isEmpty)
    }
}

private final class MockAmbientAudioEngine: AudioEngineControlling {
    var isRunning = false
    var outputChannelCount: AVAudioChannelCount = 2
    var outputSampleRate = 44100.0
    var mixerVolume: Float = 0
    var prepareCalled = false
    var startCalled = false
    var stopCalled = false
    var pauseCalled = false
    var attachedNodes: [AVAudioNode] = []
    var detachedNodes: [AVAudioNode] = []

    func setMixerVolume(_ volume: Float) {
        mixerVolume = volume
    }

    func attachAndConnect(_ node: AVAudioNode) {
        attachedNodes.append(node)
    }

    func detach(_ node: AVAudioNode) {
        detachedNodes.append(node)
    }

    func prepare() {
        prepareCalled = true
    }

    func start() throws {
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
