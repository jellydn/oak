# INTEGRATIONS.md — External Integrations

## Third-Party Services

### None

Oak has **zero** cloud dependencies. The app operates entirely offline with no:

- Account creation
- Cloud sync
- API calls
- Telemetry/analytics
- Crash reporting

This is by design per the MVP constraints (FR-14).

## External Systems

### Sparkle Auto-Update Framework

- **Package**: `sparkle-project/Sparkle` 2.6.4+
- **Purpose**: Automatic application updates
- **Configuration**: Public EdDSA key in `SPARKLE_PUBLIC_ED_KEY` in `project.yml`
- **Update feed**: Appcast XML at `appcast.xml` (root of repo)
- **Behavior**:
  - Checks for updates on launch (configurable interval)
  - Automatic download optional (default: off)
  - Manual check available via Settings
- **Deployment**: CI pipeline (`release.yml`) generates appcast + Homebrew cask updates

### macOS System Services

| Service               | Usage                                                 |
| --------------------- | ----------------------------------------------------- |
| **UserNotifications** | Local notifications for session completion            |
| **AVFoundation**      | Audio playback and generation                         |
| **CoreGraphics**      | Display identification (`CGMainDisplayID`)            |
| **NSScreen**          | Screen detection, notch detection, window positioning |

## Notifications

- **Framework**: `UserNotifications` (local only)
- **Authorization**: Requested on user action from Settings view
- **Content**:
  - Work completion: "Focus Session Complete!" / "Great work! Time for a break."
  - Break completion: "Break Complete!" / "Ready to focus again?"
- **Sound**: `.default` notification sound
- **Status**: Tracked via `@Published private(set) var isAuthorized: Bool`

## Audio System

- **Bundled tracks**: 5 ambient `.m4a` files in `Oak/Oak/Resources/Sounds/`
- **Generated tracks**: Procedural noise via `AVAudioSourceNode` for all tracks (fallback)
- **Sources**: Pixabay under Pixabay Content License (attributed in `DEVELOPMENT.md`)

## App Store / Distribution

- **Distribution channel**: Homebrew cask (`Casks/oak.rb`)
- **Signing**: Not yet Apple Developer signed (security warning noted in README)
- **CI/CD**: GitHub Actions workflows for release, auto-release, appcast update, Pages deployment

## No Database

- No Core Data, SQLite, or any database system
- All persistence via `UserDefaults` (JSON-encoded arrays)
- 90-day retention policy with automatic pruning

## No Authentication

- No auth providers (OAuth, Apple ID, etc.)
- No user accounts
- No API keys or secrets (except Sparkle EdDSA key for appcast verification)
