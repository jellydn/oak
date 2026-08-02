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
    private let ambientPlayback: AmbientAudioPlayback
    private let logger = Logger(subsystem: "com.productsway.oak.app", category: "AudioManager")

    init(audioEngineFactory: @escaping () -> any AudioEngineControlling = { AudioEngineAdapter() }) {
        ambientPlayback = AmbientAudioPlayback(audioEngineFactory: audioEngineFactory)
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
        ambientPlayback.pause()
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

        guard ambientPlayback.resume() else {
            logger.error("Failed to resume audio engine")
            return
        }
        isPlaying = true
    }

    func stop() {
        ambientPlayback.stop()

        audioPlayer?.stop()
        audioPlayer = nil

        isPlaying = false
        selectedTrack = .none
    }

    private func updateAudioEngineVolume() {
        audioPlayer?.volume = Float(volume)
        ambientPlayback.setVolume(volume)
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

        guard ambientPlayback.play(track: track, volume: volume) else {
            logger.error("Failed to start ambient audio")
            isPlaying = false
            selectedTrack = .none
            return
        }

        isPlaying = true
        selectedTrack = track
    }

    deinit {
        audioPlayer?.stop()
    }
}
