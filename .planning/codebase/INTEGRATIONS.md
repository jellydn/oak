# INTEGRATIONS — Oak External Integrations

## External Services

Oak is a **local-first macOS app** with minimal external dependencies. No cloud sync, no remote APIs, no databases.

| Service | Purpose | Details |
| --- | --- | --- |
| [Sparkle](https://sparkle-project.org/) | App updates | Check for new versions, download, and install updates. Configured via `SparkleUpdater.swift` using `SPUUpdaterDelegate`. Appcast hosted at `appcast.xml`. |
| GitHub Releases | Distribution | Release assets built via `scripts/release/build-release-assets.sh`, published to GitHub Releases, referenced by Sparkle appcast |
| Homebrew | Distribution | `Casks/oak.rb` — Homebrew cask formula for `brew install` |
| GitHub Pages | Documentation | Static docs site at `docs/index.html` deployed via `deploy-pages.yml` |

## System Integrations

| Integration | File | Purpose |
| --- | --- | --- |
| User Notifications | `NotificationService.swift` | Local notifications on session/break completion via `UNUserNotificationCenter` |
| NSSound | `FocusSessionViewModel.swift` | System beep for session completion (`NSSound.beep()`) |
| NSScreen | `NSScreen+UUID.swift`, `NSScreen+DisplayTarget.swift` | Display detection, notch detection, screen identification |
| AVFoundation | `AudioManager.swift` | Audio playback for ambient sounds, noise generation |

## Protocol Contracts

```swift
// DI for session completion notifications
internal protocol SessionCompletionNotifying {
    func sendSessionCompletionNotification(isWorkSession: Bool)
}

// DI for completion sound
internal protocol SessionCompletionSoundPlaying {
    func playCompletionSound()
}

// DI for audio engine (testability)
internal protocol AudioEngineProtocol {
    var isRunning: Bool { get }
    func setMixerVolume(_ volume: Float)
    func attachAndConnect(_ node: AVAudioNode)
    func detach(_ node: AVAudioNode)
    func prepare()
    func start() throws
    func stop()
    func pause()
}
```

## No Integrations

- ❌ No analytics / telemetry
- ❌ No cloud sync or backend API
- ❌ No third-party authentication
- ❌ No payment processing
- ❌ No crash reporting service
- ❌ No remote config / feature flags
