# Integrations - Oak External Integrations

**Last Updated**: 2025-02-13

## Overview

Oak is designed as a **local-first** macOS application with minimal external dependencies. It integrates with system APIs and one external service for updates.

---

## macOS System Integrations

### UserNotifications Framework

| Purpose | Usage |
|----------|--------|
| Session alerts | Send notifications when focus/break sessions complete |
| Permission management | Request notification authorization via system prompts |

**Implementation**: `NotificationService.swift`

**Key Features**:
- Alert and sound notifications
- Settings deep linking (macOS Notification preferences)
- Graceful fallback when permission denied

---

### AVFoundation Audio

| Purpose | Usage |
|----------|--------|
| Audio playback | Loop ambient sounds (rain, forest, cafe, brown noise, lo-fi) |
| Audio engine | Procedural audio generation using `AVAudioSourceNode` |
| Volume control | Real-time volume adjustment |

**Implementation**: `AudioManager.swift`

**Audio Sources** (priority order):
1. Bundled assets in `Oak/Oak/Resources/Sounds/` (`.m4a`, `.wav`, `.mp3`)
2. Procedural generation fallback (noise algorithms)

**Supported Formats**:
- AAC (`.m4a`) - preferred
- WAV (`.wav`)
- MP3 (`.mp3`)

---

### NSScreen / Display Integration

| Purpose | Usage |
|----------|--------|
| Multi-monitor support | Target main display or notched display |
| Notch positioning | Center window on notch area |
| Screen change detection | Reposition on display configuration changes |

**Implementation**: `NSScreen+DisplayTarget.swift`, `NotchWindowController.swift`

**Display Targets**:
- `mainDisplay` - Primary monitor
- `notchedDisplay` - Monitor with hardware notch

---

### NSWorkspace Integration

| Purpose | Usage |
|----------|--------|
| URL opening | Open release pages in default browser |
| Notification settings | Deep link to macOS System Preferences |

**Implementation**: `UpdateChecker.swift`, `NotificationService.swift`

---

### UserDefaults Persistence

| Purpose | Usage |
|----------|--------|
| Settings storage | Preset durations, display preferences, sound settings |
| Progress tracking | Daily focus minutes, completed sessions, streak data |

**Implementation**: `PresetSettingsStore.swift`, `ProgressManager.swift`

**Storage Keys** (namespace: `com.productsway.oak.app`):
- `preset.short.workMinutes` - Short preset work duration
- `preset.short.breakMinutes` - Short preset break duration
- `preset.short.longBreakMinutes` - Short preset long break duration
- `preset.long.workMinutes` - Long preset work duration
- `preset.long.breakMinutes` - Long preset break duration
- `preset.long.longBreakMinutes` - Long preset long break duration
- `session.roundsBeforeLongBreak` - Rounds before long break triggers
- `display.target` - Display target (main/notched)
- `display.main.id` - Main display ID
- `display.notched.id` - Notched display ID
- `session.completion.playSound` - Play sound on session complete
- `countdown.displayMode` - Countdown display mode (number/ring)
- `progressHistory` - Encoded JSON of `[ProgressData]`

---

## External API Integrations

### GitHub API (Read-Only)

| Purpose | Check for app updates |
|----------|----------------------|
| **Endpoint** | `https://api.github.com/repos/jellydn/oak/releases/latest` |
| **Method** | GET (anonymous) |
| **Auth** | None (public API) |
| **Rate Limiting** | Respects 403/429 responses, silent skip |
| **Data Fetched** | Latest release tag name, HTML URL |

**Implementation**: `UpdateChecker.swift`

**Request Headers**:
```
Accept: application/vnd.github+json
User-Agent: Oak/{currentVersion}
```

**Usage Flow**:
1. On app launch, check latest release from GitHub
2. Compare with `CFBundleShortVersionString` from Info.plist
3. Show update alert if newer version available
4. Store last prompted version in UserDefaults (24-hour cooldown)

**Rate Limit Handling**:
- Timeout: 10 seconds
- Silent skip on 403/429 responses
- No retry logic

---

## Release Distribution

### GitHub Releases

| Purpose | Distribute app builds |
|----------|---------------------|
| **Artifacts** | `Oak-{version}.dmg`, `Oak-{version}.zip` |
| **Trigger** | Push to `main` (auto-release) or manual tag push |
| **Signing** | Unsigned (user bypasses Gatekeeper) |
| **Notarization** | None |

**Implementation**: `.github/workflows/auto-release.yml`, `release.yml`

**Auto-Release Process**:
1. Detect push to `main`
2. Check if commit already has a tag
3. Increment patch version (e.g., 0.0.0 -> 0.0.1)
4. Create and push Git tag
5. Build DMG and ZIP using `scripts/release/build-release-assets.sh`
6. Publish release with artifacts

---

### Homebrew Cask

| Purpose | Package distribution via Homebrew |
|----------|----------------------------------|
| **Tap** | `jellydn/oak` |
| **Cask** | `oak` |
| **Repo** | Separate Homebrew tap repository |

**Implementation**: `.github/workflows/update-homebrew.yml`

**Update Process** (on GitHub release):
1. Download DMG from release
2. Calculate SHA256 checksum
3. Update `Casks/oak.rb` in tap repo with version and SHA256
4. Commit and push changes to tap

---

## CI/CD Integrations

### GitHub Actions

| Workflow | Trigger | Purpose |
|----------|----------|---------|
| `ci.yml` | Push to `main`, PRs | Lint, build, test |
| `auto-release.yml` | Push to `main` | Auto-increment version and release |
| `release.yml` | Tag push `v*`, manual | Build release artifacts |
| `update-homebrew.yml` | Release published | Update Homebrew cask |

**Runner**: `macos-15` (latest)
**Xcode Version**: Latest stable via `maxim-lobanov/setup-xcode@v1`

---

## Data Flow Diagram

```
+-------------------+     +------------------+     +------------------+
|   macOS System    |<--->|   Oak App        |<--->|   GitHub API     |
| (UserNotifications)|     | (SwiftUI/AppKit)  |     | (Release checks)|
+-------------------+     +------------------+     +------------------+
         ^                       ^  ^
         |                       |  |
         v                       |  |
+-------------------+          |  |
|  AVFoundation     |---------+  |
|  (Audio Engine)   |             |
+-------------------+             |
                                 v
                        +------------------+
                        |  UserDefaults    |
                        |  (Persistence)  |
                        +------------------+
```

---

## Security Considerations

| Integration | Security Notes |
|-------------|----------------|
| **GitHub API** | Public read-only, no secrets required |
| **UserDefaults** | Local-only, no cloud sync |
| **Notification Settings** | System-managed permissions |
| **URL Opening** | Validates GitHub host before opening |
| **Homebrew Tap** | Public repo, PR review required |

---

## Future Integrations (Not Implemented)

The following are explicitly **out of scope** for MVP:

| Feature | Notes |
|---------|--------|
| Cloud sync | Local-only persistence |
| Global hotkeys | No system-wide keyboard shortcuts |
| Calendar integration | No event-based focus sessions |
| Analytics | No tracking or telemetry |
| Auth providers | No user accounts required |
