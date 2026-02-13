import AVFoundation
import Combine
import Foundation
import os

internal class AudioManager: ObservableObject {
    @Published var selectedTrack: AudioTrack = .none
    @Published var volume: Double = 0.5 {
        didSet {
            updateAudioEngineVolume()
        }
    }

    @Published var isPlaying: Bool = false

    private var audioPlayer: AVAudioPlayer?
    private var audioEngine: AVAudioEngine?
    private var audioNodes: [AVAudioNode] = []
    private var noiseGenerator = NoiseGenerator()
    private let logger = Logger(subsystem: "com.oak.app", category: "AudioManager")

    func play(track: AudioTrack) {
        guard track != .none else {
            stop()
            return
        }

        #if os(iOS) || os(tvOS) || os(watchOS)
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                logger.error("Failed to set up audio session: \(error.localizedDescription, privacy: .public)")
            }
        #endif

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

    private func updateAudioEngineVolume() {
        audioPlayer?.volume = Float(volume)

        if let mainMixerNode = audioEngine?.mainMixerNode {
            mainMixerNode.outputVolume = Float(volume)
        }
    }

    func setVolume(_ newVolume: Double) {
        volume = max(0, min(1, newVolume))
    }

    private func generateAmbientSound(for track: AudioTrack) {
        stop()
        noiseGenerator = NoiseGenerator()

        let engine = AVAudioEngine()
        let mainMixer = engine.mainMixerNode
        mainMixer.outputVolume = Float(volume)

        var sourceNode: AVAudioNode?

        switch track {
        case .none:
            return

        case .brownNoise:
            sourceNode = createBrownNoiseNode(generator: noiseGenerator)

        case .rain:
            sourceNode = createRainNode(generator: noiseGenerator)

        case .forest:
            sourceNode = createForestNode(generator: noiseGenerator)

        case .cafe:
            sourceNode = createCafeNode(generator: noiseGenerator)

        case .lofi:
            sourceNode = createLofiNode(generator: noiseGenerator)
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
            selectedTrack = track
        } catch {
            logger.error("Failed to start audio engine: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func createBrownNoiseNode(generator: NoiseGenerator) -> AVAudioSourceNode {
        AVAudioSourceNode { _, _, _, outputBuffer in
            Self.fillOutputBuffer(outputBuffer) {
                generator.generateBrownNoise()
            }
            return noErr
        }
    }

    private func createRainNode(generator: NoiseGenerator) -> AVAudioSourceNode {
        AVAudioSourceNode { _, _, _, outputBuffer in
            Self.fillOutputBuffer(outputBuffer) {
                generator.generateRainNoise()
            }
            return noErr
        }
    }

    private func createForestNode(generator: NoiseGenerator) -> AVAudioSourceNode {
        AVAudioSourceNode { _, _, _, outputBuffer in
            Self.fillOutputBuffer(outputBuffer) {
                generator.generateForestNoise()
            }
            return noErr
        }
    }

    private func createCafeNode(generator: NoiseGenerator) -> AVAudioSourceNode {
        AVAudioSourceNode { _, _, _, outputBuffer in
            Self.fillOutputBuffer(outputBuffer) {
                generator.generateCafeNoise()
            }
            return noErr
        }
    }

    private func createLofiNode(generator: NoiseGenerator) -> AVAudioSourceNode {
        AVAudioSourceNode { _, _, _, outputBuffer in
            Self.fillOutputBuffer(outputBuffer) {
                generator.generateLofiNoise()
            }
            return noErr
        }
    }

    private static func fillOutputBuffer(_ outputBuffer: UnsafeMutablePointer<AudioBufferList>, sample: () -> Float) {
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

    deinit {
        stop()
    }
}

private final class NoiseGenerator {
    private var brownNoiseLast: Float = 0
    private var rainSeed: Float = 0

    func generateBrownNoise() -> Float {
        let white = Float.random(in: -1 ... 1)
        brownNoiseLast = (brownNoiseLast + (0.02 * white)) / 1.02
        brownNoiseLast *= 3.5
        brownNoiseLast = max(-1, min(1, brownNoiseLast))
        return brownNoiseLast * 0.15
    }

    func generateRainNoise() -> Float {
        rainSeed += 0.01
        let maxSeed = Float.pi * 2000
        if rainSeed > maxSeed {
            rainSeed -= maxSeed
        }
        let noise = Float.random(in: -0.3 ... 0.3)
        let modulation = sin(rainSeed * 2.0) * 0.5 + 0.5
        return noise * modulation
    }

    func generateForestNoise() -> Float {
        let noise = Float.random(in: -0.4 ... 0.4)
        let modulation = sin(Float.random(in: 0 ... Float.pi * 2)) * 0.3
        return (noise + modulation) * 0.5
    }

    func generateCafeNoise() -> Float {
        let base = Float.random(in: -0.2 ... 0.2)
        let chatter = sin(Float.random(in: 0 ... Float.pi * 10)) * 0.15
        return base + chatter
    }

    func generateLofiNoise() -> Float {
        let noise = Float.random(in: -0.25 ... 0.25)
        let vinyl = Float.random(in: -0.05 ... 0.05)
        return noise + vinyl
    }
}
