import AVFoundation
import Foundation

// MARK: - AudioEngineControlling

internal protocol AudioEngineControlling {
    var isRunning: Bool { get }
    var outputChannelCount: AVAudioChannelCount { get }
    var outputSampleRate: Double { get }
    func setMixerVolume(_ volume: Float)
    func attachAndConnect(_ node: AVAudioNode)
    func detach(_ node: AVAudioNode)
    func prepare()
    func start() throws
    func stop()
    func pause()
}

// MARK: - AudioEngineAdapter

internal final class AudioEngineAdapter: AudioEngineControlling {
    private let engine = AVAudioEngine()

    internal var isRunning: Bool {
        engine.isRunning
    }

    internal var outputChannelCount: AVAudioChannelCount {
        engine.outputNode.outputFormat(forBus: 0).channelCount
    }

    internal var outputSampleRate: Double {
        engine.outputNode.outputFormat(forBus: 0).sampleRate
    }

    internal func setMixerVolume(_ volume: Float) {
        engine.mainMixerNode.outputVolume = volume
    }

    internal func attachAndConnect(_ node: AVAudioNode) {
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: nil)
    }

    internal func detach(_ node: AVAudioNode) {
        engine.detach(node)
    }

    internal func prepare() {
        engine.prepare()
    }

    internal func start() throws {
        try engine.start()
    }

    internal func stop() {
        engine.stop()
    }

    internal func pause() {
        engine.pause()
    }
}
