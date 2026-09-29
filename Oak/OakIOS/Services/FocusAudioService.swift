import AVFoundation
import Combine
import Foundation

@MainActor
internal final class FocusAudioService: ObservableObject {
    @Published private(set) var selectedTrack: FocusAmbientTrack = .none
    @Published private(set) var isPlaying: Bool = false
    @Published internal var volume: Double = 0.5 {
        didSet {
            player?.volume = Float(volume)
        }
    }

    private var player: AVAudioPlayer?

    internal func select(_ track: FocusAmbientTrack, playImmediately: Bool) {
        stop()
        selectedTrack = track
        if playImmediately {
            playSelected()
        }
    }

    internal func playSelected() {
        guard let fileName = selectedTrack.bundledFileName,
              let url = Bundle.main.url(forResource: fileName, withExtension: "m4a")
        else {
            stop()
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = Float(volume)
            player.prepareToPlay()
            isPlaying = player.play()
            self.player = isPlaying ? player : nil
        } catch {
            stop()
        }
    }

    internal func pause() {
        player?.pause()
        isPlaying = false
    }

    internal func resume() {
        guard selectedTrack != .none else { return }
        if let player {
            isPlaying = player.play()
        } else {
            playSelected()
        }
    }

    internal func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }
}
