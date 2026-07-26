# Technology Stack

## Languages

- **Swift 5.9+** — primary language, concurrency via `async/await`, `@MainActor`, `Task`

## Runtime & Platform

- **macOS 13.0+** (Ventura) — deployment target
- **Apple Silicon** (arm64) — primary target; Intel (x86_64) supported via universal binary
- **Xcode 17.0** — development toolchain

## Frameworks & Libraries

### Apple Frameworks

| Framework | Usage |
| --- | --- |
| **SwiftUI** | All UI components (notch companion, settings, menus, popovers) |
| **AppKit** | Window management (`NSPanel`, `NSWindowController`), NSEvent monitoring, `NSSavePanel`/`NSOpenPanel`, `NSSound` |
| **Combine** | `ObservableObject`, `@Published`, `AnyCancellable`, `PassthroughSubject` — reactive data flow |
| **AVFoundation** | Ambient audio playback (`AVAudioPlayer`) |
| **Foundation** | Codable persistence (`JSONEncoder`/`JSONDecoder`), `UserDefaults`, `Timer`, date handling |
| **CoreGraphics** | Display ID management (`CGDirectDisplayID`) |
| **UserNotifications** | Local notification delivery for session completion |
| **os.log** | Structured logging (`Logger`) |

### Third-Party Dependencies

| Package | Version | Purpose |
| --- | --- | --- |
| **[Sparkle](https://github.com/sparkle-project/Sparkle)** | 2.9.4 | In-app update framework (auto-update checks, release channels) |

## Build & Tooling

| Tool | Purpose |
| --- | --- |
| **XcodeGen** (`project.yml`) | Project file generation — single source of truth for targets, sources, dependencies |
| **SwiftLint** (`.swiftlint.yml`) | Static analysis — line length (120/150), function body (50/100), file length (500/1000), naming rules |
| **SwiftFormat** (`.swiftformat`) | Code formatting — 4-space indent, 120 max width, sorted imports, `self` removal |
| **just** (`justfile`) | Task runner — `just build`, `just test`, `just lint`, `just format`, `just dev` |
| **GitHub Actions** (`.github/workflows/`) | CI — `ci.yml` (build+test+lint), `release.yml`, `auto-release.yml`, `update-appcast.yml`, `deploy-pages.yml` |
| **Prettier** (`.prettierrc`) | Markdown/YAML formatting |

## Configuration

- **`project.yml`** — XcodeGen config: targets, sources, bundle ID (`com.productsway.oak.app`), version (`0.5.40`), build (`5040`)
- **`Info.plist`** — `LSUIElement = true` (accessory app, no Dock icon), Sparkle feed URL + public EdDSA key
- **`Oak.entitlements`** — `com.apple.security.network.client` (outbound networking for Sparkle updates)
- **`appcast.xml`** — Sparkle appcast feed for update distribution
- **`prek.toml`** — Additional project metadata

## App Architecture

- **Type**: macOS accessory app (`.accessory` activation policy, `LSUIElement`)
- **UI Pattern**: Notch-only companion, no standard main window
- **Bundle ID**: `com.productsway.oak.app`
- **Current Version**: 0.5.40 (build 5040)
