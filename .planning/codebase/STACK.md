# STACK.md — Technology Stack

## Language & Runtime

| Layer | Technology | Version |
| --- | --- | --- |
| Language | Swift | 5.9+ |
| Platform | macOS | 13.0+ (Apple Silicon preferred) |
| Xcode | Xcode 16+ (`project.yml` references xcodeVersion 17.0) |

## UI Framework

| Component       | Technology                                                      |
| --------------- | --------------------------------------------------------------- |
| UI Framework    | SwiftUI                                                         |
| AppKit Bridging | `NSViewRepresentable`, `NSHostingView`, `NSPanel`               |
| Window Type     | `NSPanel` with `.borderless` + `.nonactivatingPanel` style mask |
| Notch Detection | `NSScreen.safeAreaInsets.top` for physical notch detection      |

## Core Frameworks

| Framework | Usage |
| --- | --- |
| **Combine** | Reactive bindings (`@Published`, `AnyCancellable`, `.sink`) |
| **AVFoundation** | Audio playback (bundled `.m4a` files + procedural noise generation via `AVAudioSourceNode`) |
| **UserNotifications** | Local notification delivery for session completion |
| **AppKit** | Window management, `NSScreen` extensions, `NSSound.beep()` |
| **CoreGraphics** | Display ID resolution (`CGMainDisplayID()`) |
| **Foundation** | `Timer`, `UserDefaults`, `os.Logger` |

## Third-Party Dependencies

| Package | Version | Usage |
| --- | --- | --- |
| [Sparkle](https://github.com/sparkle-project/Sparkle) | 2.9.4 | In-app update checking and distribution (`SPUUpdaterDelegate`) |

## Build System

| Tool | Purpose |
| --- | --- |
| [XcodeGen](https://github.com/yonaskolb/XcodeGen) | Project generation from `project.yml` |
| [just](https://github.com/casey/just) | Task runner (`just build`, `just test`, `just lint`) |
| xcodebuild | CI builds (GitHub Actions on `macos-26` runners) |

## Code Quality

| Tool | Configuration |
| --- | --- |
| SwiftLint | `.swiftlint.yml` (opt-in rules: `explicit_init`, `trailing_closure`, `empty_count`, etc.) |
| SwiftFormat | `.swiftformat` (indent: 4, maxwidth: 120, `wraparguments before-first`) |

## Configuration Files

| File | Purpose |
| --- | --- |
| `Oak/project.yml` | XcodeGen project definition (targets, dependencies, build settings) |
| `Oak/Oak/Info.plist` | App metadata, Sparkle feed URL, `LSUIElement = true` |
| `Oak/Oak/Oak.entitlements` | `com.apple.security.network.client` (outbound networking for Sparkle) |
| `justfile` | Task automation commands |
| `.swiftlint.yml` | Lint rule configuration |
| `.swiftformat` | Formatter rule configuration |
| `appcast.xml` | Sparkle appcast for update distribution |

## CI/CD

| Provider | Platform | File |
| --- | --- | --- |
| GitHub Actions | `macos-26` runner | `.github/workflows/ci.yml` |
| Lint | `swiftlint lint --strict` | CI job |
| Build & Test | `xcodebuild build` + `xcodebuild test` (unsigned, no code signing) | CI job |
| Release | Sparkle appcast update + Homebrew cask | `.github/workflows/release.yml` |
