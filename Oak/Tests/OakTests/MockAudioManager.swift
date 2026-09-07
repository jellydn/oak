import AVFoundation
@testable import Oak

@MainActor
internal final class MockAudioManager: AudioManager {
    init() {
        super.init { MockTestAudioEngine() }
    }

    override func play(track: AudioTrack) {
        play(sound: .builtIn(track))
    }

    override func play(sound: AudioSelection) {
        guard !sound.isNone else {
            stop()
            return
        }
        selectedSound = sound
        isPlaying = true
    }

    override func pause() {
        isPlaying = false
    }

    override func resume() {
        guard !selectedSound.isNone else { return }
        isPlaying = true
    }

    override func stop() {
        isPlaying = false
        selectedSound = .builtIn(.none)
    }
}

private final class MockTestAudioEngine: AudioEngineControlling {
    var isRunning: Bool = false
    var outputChannelCount: UInt32 = 2
    var outputSampleRate: Double = 44100

    func setMixerVolume(_: Float) {}
    func attachAndConnect(_: AVFoundation.AVAudioNode) {}
    func detach(_: AVFoundation.AVAudioNode) {}
    func prepare() {}
    func start() throws {
        isRunning = true
    }

    func stop() {
        isRunning = false
    }

    func pause() {
        isRunning = false
    }
}
