# Technology Stack

**Analysis Date:** 2026-02-13

## Languages
**Primary:**
- Swift 5.9+ - Entire application (models, views, services, tests)
**Secondary:**
- YAML - XcodeGen project config (`project.yml`), CI workflows
- Shell/Bash - Build scripts (`scripts/release/`), `justfile`

## Runtime
**Environment:**
- macOS 13.0+ (Ventura), Apple Silicon / Intel
- Xcode 16 (latest-stable in CI)
**Package Manager:**
- Swift Package Manager (SPM) - `Package.swift` present but used only for `swift build` check; primary build via Xcode project
- Lockfile: N/A (no `Package.resolved` — zero external Swift packages)

## Frameworks
**Core:**
- SwiftUI - UI layer (notch companion view, popovers, controls)
- AppKit - Window management (`NSPanel`, `NSWindowController`, `NSMenu`, `NSAlert`)
- AVFoundation - Procedural ambient audio generation (`AVAudioEngine`, `AVAudioSourceNode`)
- Combine - Reactive data flow (`@Published`, `ObservableObject`)
- Foundation - Data persistence, networking, timers
**Testing:**
- XCTest - Unit tests (8 test files under `Tests/OakTests/`)
**Build/Dev:**
- XcodeGen - Project generation from `project.yml`
- xcodebuild - Build & test runner
- just (justfile) - Task runner for build, test, clean commands

## Key Dependencies
**Critical:**
- Zero external Swift packages — all functionality uses Apple platform frameworks only
**Infrastructure:**
- `os.log` (`Logger`) - Structured logging (used in `UpdateChecker`)
- `UserDefaults` - Local data persistence for progress history and update prompts

## Configuration
**Environment:**
- No environment variables required for development
- `LSUIElement: true` / `LSBackgroundOnly: true` — runs as accessory app (no Dock icon)
- Bundle ID: `com.oak.app`
**Build:**
- `project.yml` — XcodeGen project definition
- `Package.swift` — SPM manifest (swift-tools-version:5.9)
- `Oak.entitlements` — empty entitlements plist
- `justfile` — build/test task automation

## Platform Requirements
**Development:**
- macOS 13.0+
- Xcode 16+ (with Swift 5.9+ toolchain)
- XcodeGen (`brew install xcodegen`)
- just (`brew install just`)
**Production:**
- macOS 13.0+ (Ventura or later)
- Distributed as DMG and ZIP via GitHub Releases

---
*Stack analysis: 2026-02-13*
