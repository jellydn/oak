import AVFoundation
import Combine
import Foundation
import os

// MARK: - AudioManager

@MainActor
internal class AudioManager: ObservableObject {
    @Published var selectedTrack: AudioTrack = .none
    @Published var volume: Double = 0.5 {
        didSet {
            updateAudioEngineVolume()
        }
    }

    @Published var isPlaying: Bool = false

    private var audioPlayer: AVAudioPlayer?
    private var audioEngine: (any AudioEngineProtocol)?
    private var audioNodes: [AVAudioNode] = []
    private let logger = Logger(subsystem: "com.productsway.oak.app", category: "AudioManager")
    private let audioEngineFactory: () -> any AudioEngineProtocol

    init(audioEngineFactory: @escaping () -> any AudioEngineProtocol = { AudioEngineAdapter() }) {
        self.audioEngineFactory = audioEngineFactory
    }

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

        if playBundledTrack(track) {
            return
        }

        generateAmbientSound(for: track)
    }

    /// Pauses all audio playback.
    /// Stops both the audio player and audio engine, and sets isPlaying to false.
    func pause() {
        audioPlayer?.pause()
        audioEngine?.pause()
        isPlaying = false
    }

    /// Resumes audio playback.
    /// If an audio player exists, it resumes playing. Otherwise, starts the audio engine.
    func resume() {
        if let player = audioPlayer {
            player.play()
            isPlaying = true
            return
        }

        guard let engine = audioEngine else { return }

        do {
            try engine.start()
            isPlaying = true
        } catch {
            logger.error("Failed to resume audio engine: \(error.localizedDescription, privacy: .public)")
        }
    }

    func stop() {
        detachSourceNodes()
        audioEngine?.stop()
        audioEngine = nil

        audioPlayer?.stop()
        audioPlayer = nil

        isPlaying = false
        selectedTrack = .none
    }

    private func detachSourceNodes() {
        for node in audioNodes {
            node.removeTap(onBus: 0)
            audioEngine?.detach(node)
        }
        audioNodes.removeAll()
    }

    private func updateAudioEngineVolume() {
        audioPlayer?.volume = Float(volume)
        audioEngine?.setMixerVolume(Float(volume))
    }

    func setVolume(_ newVolume: Double) {
        volume = max(0, min(1, newVolume))
    }

    private func playBundledTrack(_ track: AudioTrack) -> Bool {
        guard let url = bundledAudioURL(for: track) else {
            logger.debug("No bundled asset for \(track.rawValue, privacy: .public), using generated fallback")
            return false
        }

        stop()

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = Float(volume)
            player.prepareToPlay()
            player.play()

            audioPlayer = player
            isPlaying = true
            selectedTrack = track
            return true
        } catch {
            let trackName = track.rawValue
            let errorDescription = error.localizedDescription
            logger.error("Bundled track failed \(trackName, privacy: .public): \(errorDescription, privacy: .public)")
            return false
        }
    }

    private func bundledAudioURL(for track: AudioTrack) -> URL? {
        guard let baseName = track.bundledFileBaseName else {
            return nil
        }

        for fileExtension in AudioTrack.supportedAudioExtensions {
            if let url = Bundle.main.url(forResource: baseName, withExtension: fileExtension) {
                return url
            }
        }

        return nil
    }

    private func generateAmbientSound(for track: AudioTrack) {
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

    deinit {
        let engine = audioEngine
        let nodes = audioNodes
        let player = audioPlayer

        engine?.stop()
        nodes.forEach { $0.removeTap(onBus: 0) }
        player?.stop()
    }
}
