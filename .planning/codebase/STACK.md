# Stack - Oak Technology Stack

**Last Updated**: 2025-02-13

## Languages

| Language | Version | Usage |
|-----------|----------|--------|
| Swift | 5.9+ | Primary language for macOS app |
| Shell | Bash | Build scripts, CI/CD workflows |

## Runtime

| Component | Version | Notes |
|-----------|----------|--------|
| macOS | 13.0+ | Minimum deployment target |
| Apple Silicon | Recommended | Primary target architecture |
| Xcode | 17.0 | Required for building |

## Frameworks & Libraries

| Framework | Purpose | Usage |
|-----------|----------|--------|
| **SwiftUI** | UI Framework | Main UI for views, notch companion interface |
| **AppKit** | macOS App Framework | NSWindow, NSPanel, NSWorkspace integration |
| **AVFoundation** | Audio | AVAudioPlayer, AVAudioEngine for ambient sound playback |
| **UserNotifications** | Notifications | UNUserNotificationCenter for session completion alerts |
| **Combine** | Reactive Streams | @Published properties, cancellables for state management |
| **Foundation** | Core Utilities | Data persistence, logging, networking |
| **CoreGraphics** | Display | Display ID handling for multi-monitor support |
| **os.log** | Logging | Structured logging throughout the app |

## Build Tools

| Tool | Version | Purpose |
|------|----------|---------|
| **XcodeGen** | Latest | Project generation from `project.yml` |
| **xcodebuild** | CLI | Building, testing from command line |
| **just** | Latest | Task runner for build commands |
| **SwiftLint** | Latest | Code linting with custom rules |
| **SwiftFormat** | Latest | Code formatting and style |

## Configuration

### Project Configuration

- **Config File**: `Oak/project.yml` (XcodeGen)
- **Bundle ID**: `com.productsway.oak.app`
- **Marketing Version**: 0.0.0 (auto-incremented)
- **Build Version**: CI-based (GitHub Actions run number)
- **LSUIElement**: `true` (menu bar only, no Dock icon)

### Code Style Configuration

| Setting | Value | Location |
|---------|--------|----------|
| Indent | 4 spaces | `.swiftformat` |
| Max line width | 120 chars (warning), 150 (error) | `.swiftlint.yml` |
| Semicolons | Never | `.swiftformat` |
| Import grouping | testable-bottom | `.swiftformat` |
| Closure spacing | Enforced | `.swiftlint.yml` |

### Custom SwiftLint Rules

| Rule | Purpose |
|-------|---------|
| `explicit_init` | Require explicit `init()` calls |
| `explicit_top_level_acl` | Require explicit access control |
| `trailing_closure` | Enforce trailing closure syntax |
| `empty_count` | Prefer `isEmpty` over `count == 0` |
| `first_where` | Prefer `first(where:)` over filter |
| `modifier_order` | Enforce SwiftUI modifier order |
| `toggle_bool` | Prefer `toggle()` over assignment |
| `no_print_statements` | Warn against `print()` in production |

## Dependencies

### External Dependencies

**None** - Oak uses only Apple SDKs. No third-party Swift packages or CocoaPods.

### System Requirements

| Requirement | Minimum | Recommended |
|-------------|-----------|--------------|
| macOS | 13.0+ | 14.0+ |
| Architecture | x86_64 / arm64 | arm64 (Apple Silicon) |
| RAM | - | 4GB+ |

## Development Tools

| Tool | Purpose |
|------|---------|
| **just** | Command runner for build/test/lint/format |
| **SwiftLint** | Code quality enforcement |
| **SwiftFormat** | Code formatting consistency |
| **xcodegen** | Generate Xcode project from YAML |

## Asset Bundles

| Asset Type | Format | Location |
|------------|---------|----------|
| Ambient Sounds | `.m4a`, `.wav`, `.mp3` | `Oak/Oak/Resources/Sounds/` |
| App Icon | Asset Catalog | `Oak/Oak/Resources/Assets.xcassets/` |
| SF Symbols | Built-in | System-provided icons |

## Testing

| Framework | Usage |
|-----------|--------|
| **XCTest** | Unit testing for ViewModels, Services |
| **XCTest** | Async tests with `async throws` |

### Test Structure

- Tests mirror source structure under `Tests/OakTests/`
- Isolated UserDefaults per test class
- MainActor isolation for UI tests
