# STACK.md — Oak Technology Stack

## Language & Runtime

- **Language**: Swift 5.9+ (conforms to Swift 6 concurrency model via `@MainActor` annotations)
- **Runtime**: Native macOS app, compiled via Xcode with Apple Silicon target
- **Swift version config**: `--swiftversion 6.2` in `.swiftformat`

## Platform

- **OS**: macOS 13+ (Ventura minimum)
- **Architecture**: Apple Silicon (M1+), Intel unsupported per PRD
- **UI Framework**: SwiftUI (App lifecycle via `@main` SwiftUI `App` protocol)
- **Window System**: AppKit (`NSPanel`, `NSWindowController`, `NSApplicationDelegate`)

## Core Frameworks

| Framework | Usage |
|-----------|-------|
| **SwiftUI** | All UI views, settings scene, popover support |
| **AppKit** | Window management (`NSPanel`), application lifecycle, `NSScreen`, `NSHostingView` |
| **AVFoundation** | Audio playback via `AVAudioPlayer` and `AVAudioEngine` |
| **Combine** | Reactive bindings (`@Published`, `.sink`, `AnyCancellable`) |
| **UserNotifications** | Session completion notifications |
| **CoreGraphics** | Display ID management (`CGDirectDisplayID`) |
| **os** | Structured logging (`Logger`) |

## External Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| **Sparkle** | 2.6.4+ | Auto-update framework (appcast-based) |

Managed via XcodeGen (`project.yml`) with Swift Package Manager integration.

## Build System

- **Project generation**: XcodeGen (`project.yml`)
- **Build tool**: `xcodebuild` CLI via `just` recipes
- **Task runner**: `just` (see `justfile`)
- **Xcode version**: 17.0 (specified in `project.yml`)

## Code Quality Tooling

### Linting — SwiftLint

- Config: `.swiftlint.yml`
- Mode: `--strict` (all violations treated as errors)
- Opt-in rules include: `explicit_init`, `explicit_top_level_acl`, `trailing_closure`, `first_where`, `toggle_bool`, `modifier_order`, `vertical_parameter_alignment_on_call`, `closure_spacing`, `empty_count`, `sorted_first_last`, `redundant_type_annotation`, `yoda_condition`, `unneeded_parentheses_in_closure_argument`
- Analyzer rules: `explicit_self`, `unused_import`
- Disabled: `todo`, `trailing_whitespace`
- Custom rule: `no_print_statements` (warns on `print()`)

### Formatting — SwiftFormat

- Config: `.swiftformat`
- Indent: 4 spaces
- Max width: 120
- Wrapping: `before-first` for arguments, parameters, collections
- Self: `remove`
- Imports: `testable-bottom` grouping

## Configuration Files

| File | Purpose |
|------|---------|
| `Oak/project.yml` | XcodeGen project definition (targets, dependencies, version) |
| `Oak/Oak/Info.plist` | App bundle metadata, launch config |
| `Oak/Oak/Oak.entitlements` | Sandbox entitlements |
| `.swiftlint.yml` | Lint rules and exclusions |
| `.swiftformat` | Formatting rules |
| `justfile` | Task automation recipes |
| `Oak/Oak.xcodeproj/xcshareddata/xcschemes/Oak.xcscheme` | Xcode scheme (test targets, build config) |

## Versioning

- **Marketing version**: From latest `git` tag matching `v*` (e.g., `0.5.29`)
- **Build number**: Git commit count via `git rev-list --count HEAD`
- **Bundle identifier**: `com.productsway.oak.app`

## Persistence

- **Storage**: `UserDefaults` (no Core Data, no SQLite)
- **Purpose**: Session history (`ProgressData`), preset settings (`PresetSettingsStore`), audio track preferences
- **Retention**: 90-day window for session records
- **Format**: JSON-encoded `ProgressData` array under key `progressHistory`
