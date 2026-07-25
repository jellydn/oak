# INTEGRATIONS.md — External Services & APIs

## Sparkle Update Framework

- **Service**: [Sparkle 2](https://sparkle-project.org/) (self-hosted)
- **Purpose**: In-app update distribution
- **Files**: `Oak/Oak/Services/SparkleUpdater.swift`
- **Configuration**:
  - Public Ed25519 key: `IjFqN1R6i4Dh8IZxQ42RtSEii7pUgS45+NvidSwQup0=` (in `project.yml`)
  - Feed URL: `https://raw.githubusercontent.com/jellydn/oak/main/appcast.xml` (in `Info.plist`)
  - Update check interval: 86,400 seconds (24 hours)
  - `SUEnableAutomaticChecks: true`
- **Protocols**: `SPUUpdaterDelegate`
- **Network entitlement**: `com.apple.security.network.client` (required for Sparkle feed fetching)

## UserNotifications Framework

- **Service**: Apple `UserNotifications` (system-level, local)
- **Purpose**: Local notification delivery for session completions
- **Files**: `Oak/Oak/Services/NotificationService.swift`
- **Authorization**: Requests `.alert` + `.sound` authorization; status is refreshed on app activation
- **Deep link**: Uses `x-apple.systempreferences:` URLs to open Notification Settings when denied
- **Protocol**: `SessionCompletionNotifying`

## UserDefaults

- **Service**: Apple `UserDefaults` (system-level, local)
- **Purpose**: Persistent settings storage
- **Files**: `Oak/Oak/Services/PresetSettingsStore.swift`, `Oak/Oak/Services/ProgressManager.swift`
- **Keys**: Prefixed with `preset.`, `display.`, `session.`, `window.`, `countdown.` domains
- **Default registration**: `userDefaults.register(defaults:)` for all keys
- **Validation**: Clamped value ranges for work/break minutes and rounds

## GitHub (CI/CD & Distribution)

- **CI**: GitHub Actions on `macos-26` runners (`.github/workflows/ci.yml`)
  - Lint: `swiftlint lint --strict`
  - Build & Test: `xcodebuild` with `CODE_SIGNING_ALLOWED=NO`
- **Release**: Automated appcast + Homebrew cask updates (`.github/workflows/release.yml`)
- **Homebrew Cask**: `Casks/oak.rb` for `brew install` distribution

## No External Backend

Oak is a fully local macOS app with no cloud backend, no user accounts, no analytics, and no telemetry. All data stays on-device in `UserDefaults`.
