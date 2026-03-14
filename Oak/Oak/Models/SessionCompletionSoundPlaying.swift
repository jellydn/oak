import AppKit

internal protocol SessionCompletionSoundPlaying {
    func playCompletionSound()
}

internal struct SystemSessionCompletionSoundPlayer: SessionCompletionSoundPlaying {
    func playCompletionSound() {
        NSSound.beep()
    }
}
