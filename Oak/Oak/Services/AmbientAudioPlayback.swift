import AVFoundation

@MainActor
internal final class AmbientAudioPlayback {
    private var audioEngine: (any AudioEngineControlling)?
    private var audioNodes: [AVAudioNode] = []
    private let audioEngineFactory: () -> any AudioEngineControlling

    internal init(audioEngineFactory: @escaping () -> any AudioEngineControlling) {
        self.audioEngineFactory = audioEngineFactory
    }

    @discardableResult
    internal func play(track: AudioTrack, volume: Double) -> Bool {
        guard track != .none else { return false }
        stopSources()

        let generator = NoiseGenerator()
        let sourceNode = AVAudioSourceNode { _, _, _, outputBuffer in
            AudioRenderBufferFiller.fill(outputBuffer, generator: generator, track: track)
            return noErr
        }

        let engine = audioEngine ?? audioEngineFactory()
        let isNewEngine = audioEngine == nil
        engine.setMixerVolume(Float(volume))

        guard engine.outputChannelCount > 0, engine.outputSampleRate > 0 else {
            engine.stop()
            return false
        }

        engine.attachAndConnect(sourceNode)
        audioNodes.append(sourceNode)
        audioEngine = engine

        if isNewEngine {
            engine.prepare()
        }

        do {
            if !engine.isRunning {
                try engine.start()
            }
            return true
        } catch {
            stop()
            return false
        }
    }

    internal func pause() {
        audioEngine?.pause()
    }

    @discardableResult
    internal func resume() -> Bool {
        guard let audioEngine else { return false }

        do {
            try audioEngine.start()
            return true
        } catch {
            return false
        }
    }

    internal func setVolume(_ volume: Double) {
        audioEngine?.setMixerVolume(Float(volume))
    }

    internal func stop() {
        stopSources()
        audioEngine?.stop()
        audioEngine = nil
    }

    private func stopSources() {
        for node in audioNodes {
            audioEngine?.detach(node)
        }
        audioNodes.removeAll()
    }

    deinit {
        let engine = audioEngine
        let nodes = audioNodes
        engine?.stop()
        nodes.forEach { engine?.detach($0) }
    }
}
