import Foundation
import AVFoundation
import Combine

@MainActor
class AudioManager: ObservableObject {
    @Published var selectedTrack: AudioTrack = .none
    @Published var volume: Double = 0.5
    @Published var isPlaying: Bool = false

    private var audioPlayer: AVAudioPlayer?
    private var audioEngine: AVAudioEngine?
    private var audioNodes: [AVAudioNode] = []

    func play(track: AudioTrack) {
        guard track != .none else {
            stop()
            return
        }

        selectedTrack = track

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }

        generateAmbientSound(for: track)
    }

    func stop() {
        audioEngine?.stop()
        audioNodes.forEach { $0.removeTap(onBus: 0) }
        audioNodes.removeAll()
        audioEngine = nil

        audioPlayer?.stop()
        audioPlayer = nil

        isPlaying = false
        selectedTrack = .none
    }

    func setVolume(_ newVolume: Double) {
        volume = max(0, min(1, newVolume))
        audioPlayer?.volume = Float(volume)

        if let mainMixerNode = audioEngine?.mainMixerNode {
            mainMixerNode.outputVolume = Float(volume)
        }
    }

    private func generateAmbientSound(for track: AudioTrack) {
        stop()

        let engine = AVAudioEngine()
        let mainMixer = engine.mainMixerNode
        mainMixer.outputVolume = Float(volume)

        var sourceNode: AVAudioNode?

        switch track {
        case .none:
            return

        case .brownNoise:
            sourceNode = createBrownNoiseNode()

        case .rain:
            sourceNode = createRainNode()

        case .forest:
            sourceNode = createForestNode()

        case .cafe:
            sourceNode = createCafeNode()

        case .lofi:
            sourceNode = createLofiNode()
        }

        if let source = sourceNode {
            engine.attach(source)
            engine.connect(source, to: mainMixer, format: source.outputFormat(forBus: 0))
            audioNodes.append(source)
        }

        audioEngine = engine
        engine.prepare()

        do {
            try engine.start()
            isPlaying = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    private func createBrownNoiseNode() -> AVAudioSourceNode {
        return AVAudioSourceNode { _, _, _, outputBuffer in
            let ablPointer = UnsafeMutableAudioBufferListIterator(outputBuffer)

            for buffer in ablPointer {
                guard let data = buffer.mData else { continue }
                let frames = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size

                for frameIndex in 0..<frames {
                    let sample = self.generateBrownNoise()
                    data.advanced(by: frameIndex * MemoryLayout<Float>.size).assumingMemoryBound(to: Float.self).pointee = sample
                }
            }

            return noErr
        }
    }

    private func createRainNode() -> AVAudioSourceNode {
        return AVAudioSourceNode { _, _, _, outputBuffer in
            let ablPointer = UnsafeMutableAudioBufferListIterator(outputBuffer)

            for buffer in ablPointer {
                guard let data = buffer.mData else { continue }
                let frames = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size

                for frameIndex in 0..<frames {
                    let sample = self.generateRainNoise()
                    data.advanced(by: frameIndex * MemoryLayout<Float>.size).assumingMemoryBound(to: Float.self).pointee = sample
                }
            }

            return noErr
        }
    }

    private func createForestNode() -> AVAudioSourceNode {
        return AVAudioSourceNode { _, _, _, outputBuffer in
            let ablPointer = UnsafeMutableAudioBufferListIterator(outputBuffer)

            for buffer in ablPointer {
                guard let data = buffer.mData else { continue }
                let frames = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size

                for frameIndex in 0..<frames {
                    let sample = self.generateForestNoise()
                    data.advanced(by: frameIndex * MemoryLayout<Float>.size).assumingMemoryBound(to: Float.self).pointee = sample
                }
            }

            return noErr
        }
    }

    private func createCafeNode() -> AVAudioSourceNode {
        return AVAudioSourceNode { _, _, _, outputBuffer in
            let ablPointer = UnsafeMutableAudioBufferListIterator(outputBuffer)

            for buffer in ablPointer {
                guard let data = buffer.mData else { continue }
                let frames = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size

                for frameIndex in 0..<frames {
                    let sample = self.generateCafeNoise()
                    data.advanced(by: frameIndex * MemoryLayout<Float>.size).assumingMemoryBound(to: Float.self).pointee = sample
                }
            }

            return noErr
        }
    }

    private func createLofiNode() -> AVAudioSourceNode {
        return AVAudioSourceNode { _, _, _, outputBuffer in
            let ablPointer = UnsafeMutableAudioBufferListIterator(outputBuffer)

            for buffer in ablPointer {
                guard let data = buffer.mData else { continue }
                let frames = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size

                for frameIndex in 0..<frames {
                    let sample = self.generateLofiNoise()
                    data.advanced(by: frameIndex * MemoryLayout<Float>.size).assumingMemoryBound(to: Float.self).pointee = sample
                }
            }

            return noErr
        }
    }

    private var brownNoiseLast: Float = 0
    private func generateBrownNoise() -> Float {
        let white = Float.random(in: -1...1)
        brownNoiseLast = (brownNoiseLast + (0.02 * white)) / 1.02
        brownNoiseLast *= 3.5
        brownNoiseLast = max(-1, min(1, brownNoiseLast))
        return brownNoiseLast * 0.15
    }

    private var rainSeed: Float = 0
    private func generateRainNoise() -> Float {
        rainSeed += 0.01
        let noise = Float.random(in: -0.3...0.3)
        let modulation = sin(rainSeed * 2.0) * 0.5 + 0.5
        return noise * modulation
    }

    private func generateForestNoise() -> Float {
        let noise = Float.random(in: -0.4...0.4)
        let modulation = sin(Float.random(in: 0...Float.pi * 2)) * 0.3
        return (noise + modulation) * 0.5
    }

    private func generateCafeNoise() -> Float {
        let base = Float.random(in: -0.2...0.2)
        let chatter = sin(Float.random(in: 0...Float.pi * 10)) * 0.15
        return base + chatter
    }

    private func generateLofiNoise() -> Float {
        let noise = Float.random(in: -0.25...0.25)
        let vinyl = Float.random(in: -0.05...0.05)
        return noise + vinyl
    }
}
