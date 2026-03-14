import AVFoundation

// MARK: - Ambient Sound Generation

@MainActor
internal extension AudioManager {
    func generateAmbientSound(for track: AudioTrack) {
        audioPlayer?.stop()
        audioPlayer = nil

        detachSourceNodes()

        let generator = NoiseGenerator()
        guard let sourceNode = createSourceNode(for: track, generator: generator) else { return }

        let engine = audioEngine ?? audioEngineFactory()
        let isNewEngine = audioEngine == nil

        engine.setMixerVolume(Float(volume))
        guard engine.outputChannelCount > 0, engine.outputSampleRate > 0 else {
            logger.error("Audio output format unavailable; skipping playback start")
            isPlaying = false
            selectedTrack = .none
            return
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
            isPlaying = true
            selectedTrack = track
        } catch {
            logger.error("Failed to start audio engine: \(error.localizedDescription, privacy: .public)")
        }
    }
}

// MARK: - Source Node Creation

@MainActor
private extension AudioManager {
    func createSourceNode(for track: AudioTrack, generator: NoiseGenerator) -> AVAudioSourceNode? {
        switch track {
        case .none: nil
        case .brownNoise: createBrownNoiseNode(generator: generator)
        case .rain: createRainNode(generator: generator)
        case .forest: createForestNode(generator: generator)
        case .cafe: createCafeNode(generator: generator)
        case .lofi: createLofiNode(generator: generator)
        }
    }
}

// MARK: - Noise Node Factories

@MainActor
private extension AudioManager {
    func createBrownNoiseNode(generator: NoiseGenerator) -> AVAudioSourceNode {
        AVAudioSourceNode { _, _, _, outputBuffer in
            Self.fillOutputBuffer(outputBuffer) {
                generator.generateBrownNoise()
            }
            return noErr
        }
    }

    func createRainNode(generator: NoiseGenerator) -> AVAudioSourceNode {
        AVAudioSourceNode { _, _, _, outputBuffer in
            Self.fillOutputBuffer(outputBuffer) {
                generator.generateRainNoise()
            }
            return noErr
        }
    }

    func createForestNode(generator: NoiseGenerator) -> AVAudioSourceNode {
        AVAudioSourceNode { _, _, _, outputBuffer in
            Self.fillOutputBuffer(outputBuffer) {
                generator.generateForestNoise()
            }
            return noErr
        }
    }

    func createCafeNode(generator: NoiseGenerator) -> AVAudioSourceNode {
        AVAudioSourceNode { _, _, _, outputBuffer in
            Self.fillOutputBuffer(outputBuffer) {
                generator.generateCafeNoise()
            }
            return noErr
        }
    }

    func createLofiNode(generator: NoiseGenerator) -> AVAudioSourceNode {
        AVAudioSourceNode { _, _, _, outputBuffer in
            Self.fillOutputBuffer(outputBuffer) {
                generator.generateLofiNoise()
            }
            return noErr
        }
    }

    static func fillOutputBuffer(_ outputBuffer: UnsafeMutablePointer<AudioBufferList>, sample: () -> Float) {
        let bufferList = UnsafeMutableAudioBufferListPointer(outputBuffer)
        for buffer in bufferList {
            guard let mData = buffer.mData else { continue }
            let frameCount = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size
            let samples = mData.assumingMemoryBound(to: Float.self)

            for index in 0 ..< frameCount {
                samples[index] = sample()
            }
        }
    }
}
