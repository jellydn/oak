import AVFoundation

// MARK: - Source Node Creation

@MainActor
internal extension AudioManager {
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
