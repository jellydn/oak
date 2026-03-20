import AVFoundation
@testable import Oak

@MainActor
internal final class MockAudioManager: AudioManager {
    init() {
        super.init(audioEngineFactory: { MockTestAudioEngine() })
    }

    override func play(track: AudioTrack) {
        guard track != .none else {
            stop()
            return
        }
        selectedTrack = track
        isPlaying = true
    }

    override func pause() {
        isPlaying = false
    }

    override func resume() {
        guard selectedTrack != .none else { return }
        isPlaying = true
    }

    override func stop() {
        isPlaying = false
        selectedTrack = .none
    }
}

private final class MockTestAudioEngine: AudioEngineProtocol {
    var isRunning: Bool = false
    var outputChannelCount: UInt32 = 2
    var outputSampleRate: Double = 44100

    func setMixerVolume(_: Float) {}
    func attachAndConnect(_: AVFoundation.AVAudioNode) {}
    func detach(_: AVFoundation.AVAudioNode) {}
    func prepare() {}
    func start() throws { isRunning = true }
    func stop() { isRunning = false }
    func pause() { isRunning = false }
}
