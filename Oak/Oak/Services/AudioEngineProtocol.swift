import AVFoundation
import Foundation

// MARK: - AudioEngineProtocol

internal protocol AudioEngineProtocol {
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

internal final class AudioEngineAdapter: AudioEngineProtocol {
    private let engine = AVAudioEngine()

    var isRunning: Bool { engine.isRunning }
    var outputChannelCount: AVAudioChannelCount { engine.outputNode.outputFormat(forBus: 0).channelCount }
    var outputSampleRate: Double { engine.outputNode.outputFormat(forBus: 0).sampleRate }

    func setMixerVolume(_ volume: Float) {
        engine.mainMixerNode.outputVolume = volume
    }

    func attachAndConnect(_ node: AVAudioNode) {
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: nil)
    }

    func detach(_ node: AVAudioNode) {
        engine.detach(node)
    }

    func prepare() { engine.prepare() }
    func start() throws { try engine.start() }
    func stop() { engine.stop() }
    func pause() { engine.pause() }
}
