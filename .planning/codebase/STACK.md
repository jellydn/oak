# STACK — Oak Technology Stack

## Language & Runtime

- **Language**: Swift 5.9+ (targeting Swift 6.2 in `.swiftformat`)
- **Platform**: macOS 13+ (Ventura minimum deployment target)
- **Architecture**: Apple Silicon (arm64), Intel (x86_64) supported

## UI Framework

- **SwiftUI** — All views are SwiftUI-based (`NotchCompanionView`, `SettingsMenuView`, `AudioMenuView`, etc.)
- **AppKit** — Used for window management (`NotchWindowController` using `NSPanel`), `NSSound.beep()`, `NSApplication.shared`
- **Combine** — Reactive state propagation (`@Published`, `ObservableObject`, `AnyCancellable`)

## Key Frameworks

| Framework           | Usage                                                                    |
| ------------------- | ------------------------------------------------------------------------ |
| `AVFoundation`      | Audio playback engine (`AudioEngineAdapter`, `AudioEngineProtocol`)      |
| `CoreGraphics`      | Display IDs (`CGDirectDisplayID`, `CGMainDisplayID`) for notch detection |
| `UserNotifications` | Local notification delivery (`NotificationService`)                      |

## Build System

- **XcodeGen** (`project.yml`) — Project file generation from declarative spec
- **xcodebuild** — Build and test via `just build`, `just test`
- **just** — Task runner (`justfile`) for build, test, lint, format, dev workflows

## Dependencies

| Dependency | Version | Purpose |
| --- | --- | --- |
| [Sparkle](https://sparkle-project.org/) | ~2.9 | Automatic app updates (`SparkleUpdater`, `SPUUpdaterDelegate`) |
| SwiftLint | — | Linting (`.swiftlint.yml`) |
| SwiftFormat | — | Code formatting (`.swiftformat`) |

## Configuration Files

| File | Purpose |
| --- | --- |
| `project.yml` | XcodeGen project spec (targets, settings, plist keys) |
| `Oak/Oak/Info.plist` | App bundle metadata |
| `Oak/Oak/Oak.entitlements` | App sandbox & capabilities |
| `.swiftlint.yml` | Lint rules (opt-in rules, line length 120/150, file length 500/1000) |
| `.swiftformat` | Format rules (indent 4, maxwidth 120, wrap before-first) |
| `justfile` | Task definitions (build, test, lint, format, dev, release) |
| `prek.toml` | Pre-commit hook configuration |
| `renovate.json` | Dependency update automation |

## Bundled Assets

- **Ambient sounds** (`.m4a`): `ambient_forest.m4a`, `ambient_cafe.m4a`, `ambient_brown_noise.m4a`, `ambient_lofi.m4a`, `ambient_rain.m4a`
- **App icon**: `Assets.xcassets/AppIcon.appiconset/`
- **Noise generation**: Programmatic fallback via `NoiseGenerator` when bundled files unavailable

## CI/CD

- **GitHub Actions**: `.github/workflows/ci.yml` (CI), `release.yml` (release), `update-appcast.yml` (Sparkle appcast), `deploy-pages.yml` (docs site), `auto-release.yml`
- **Homebrew Cask**: `Casks/oak.rb` for distribution
- **Release assets**: `scripts/release/build-release-assets.sh`
