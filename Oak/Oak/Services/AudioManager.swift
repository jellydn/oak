import AVFoundation
import Combine
import Foundation
import os

// MARK: - AudioManager

@MainActor
internal class AudioManager: ObservableObject {
    @Published var selectedSound: AudioSelection = .builtIn(.none)
    @Published private(set) var customAssets: [CustomAudioAsset] = []
    @Published private(set) var audioError: String?
    @Published var volume: Double = 0.5 {
        didSet {
            updateAudioEngineVolume()
        }
    }

    @Published var isPlaying: Bool = false

    var selectedTrack: AudioTrack {
        guard case let .builtIn(track) = selectedSound else { return .none }
        return track
    }

    private var audioPlayer: AVAudioPlayer?
    private let ambientPlayback: AmbientAudioPlayback
    private let customAudioLibrary: CustomAudioLibrary
    private let logger = Logger(subsystem: "com.productsway.oak.app", category: "AudioManager")

    init(
        audioEngineFactory: @escaping () -> any AudioEngineControlling = { AudioEngineAdapter() },
        customAudioLibrary: CustomAudioLibrary = CustomAudioLibrary()
    ) {
        ambientPlayback = AmbientAudioPlayback(audioEngineFactory: audioEngineFactory)
        self.customAudioLibrary = customAudioLibrary
        reloadCustomAssets()
    }

    func play(track: AudioTrack) {
        play(sound: .builtIn(track))
    }

    func play(sound: AudioSelection) {
        audioError = nil
        guard !sound.isNone else {
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

        switch sound {
        case let .builtIn(track):
            if playBundledTrack(track) {
                return
            }
            generateAmbientSound(for: track)
        case let .custom(asset):
            playCustomAsset(asset)
        }
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
            if player.play() {
                isPlaying = true
            } else {
                handlePlaybackError("Oak could not resume this sound.")
            }
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
        selectedSound = .builtIn(.none)
    }

    private func updateAudioEngineVolume() {
        audioPlayer?.volume = Float(volume)
        ambientPlayback.setVolume(volume)
    }

    func setVolume(_ newVolume: Double) {
        volume = max(0, min(1, newVolume))
    }

    @discardableResult
    func importCustomAudio(from sourceURL: URL) -> CustomAudioAsset? {
        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let asset = try customAudioLibrary.importAudio(from: sourceURL)
            reloadCustomAssets()
            audioError = nil
            return asset
        } catch {
            report(error)
            return nil
        }
    }

    func removeCustomAudio(_ asset: CustomAudioAsset) {
        do {
            if selectedSound == .custom(asset) {
                stop()
            }
            try customAudioLibrary.remove(asset)
            reloadCustomAssets()
            audioError = nil
        } catch {
            report(error)
            reloadCustomAssets()
        }
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
            selectedSound = .builtIn(track)
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
            selectedSound = .builtIn(.none)
            return
        }

        isPlaying = true
        selectedSound = .builtIn(track)
    }

    private func playCustomAsset(_ asset: CustomAudioAsset) {
        stop()

        do {
            let player = try AVAudioPlayer(contentsOf: asset.url)
            player.numberOfLoops = -1
            player.volume = Float(volume)
            player.prepareToPlay()
            guard player.play() else {
                handlePlaybackError("Oak could not play \(asset.name).")
                return
            }

            audioPlayer = player
            isPlaying = true
            selectedSound = .custom(asset)
        } catch {
            let message = "Oak could not play \(asset.name). The file may be missing or invalid."
            logger.error("Custom audio failed: \(error.localizedDescription, privacy: .public)")
            handlePlaybackError(message)
            reloadCustomAssets()
        }
    }

    private func reloadCustomAssets() {
        do {
            customAssets = try customAudioLibrary.assets()
        } catch {
            report(error)
        }
    }

    private func report(_ error: any Error) {
        let message = error.localizedDescription
        audioError = message
        logger.error("Custom audio library error: \(message, privacy: .public)")
    }

    private func handlePlaybackError(_ message: String) {
        stop()
        audioError = message
        logger.error("\(message, privacy: .public)")
    }

    deinit {
        audioPlayer?.stop()
    }
}
