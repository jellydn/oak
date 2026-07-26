# Technology Stack

**Analysis Date:** 2026-07-26

## Languages

**Primary:**

- Swift 5.9+ (SwiftFormat configured for Swift 6.2) — entire codebase: app target and tests

**Secondary:**

- Bash — `scripts/check-ambient-sounds.sh`, release scripts under `scripts/release/` and `scripts/ralph/`
- YAML — `Oak/project.yml` (XcodeGen), `.github/workflows/*.yml`, `renovate.json`, `prek.toml`
- XML — `Oak/Oak/Info.plist`, `appcast.xml` (Sparkle feed)

## Runtime

**Environment:**

- macOS 13.0+ (deployment target), Apple Silicon primary
- `LSUIElement: true` — runs as accessory (no Dock icon, no menu bar fallback per MVP constraint)

**Package Manager:**

- Swift Package Manager (via XcodeGen `packages:` in `Oak/project.yml`)
- Lockfile: `Package.resolved` (gitignored)

## Frameworks

**Core:**

- SwiftUI — declarative UI for notch companion view, settings menu, popovers
- AppKit — `NSPanel`/`NSWindowController` for the borderless notch window, `NSEvent` monitors for keyboard shortcuts, `NSWorkspace`, `NSScreen`
- AVFoundation — `AVAudioEngine` + `AVAudioSourceNode` for procedural ambient noise; `AVAudioPlayer` for bundled `.m4a` tracks
- UserNotifications (`UNUserNotificationCenter`) — local session-completion notifications
- CoreGraphics — `CGDirectDisplayID` display identification
- Combine — `@Published`, `AnyCancellable`, `PassthroughSubject` for reactive bindings
- os.log — `Logger` for production logging

**Testing:**

- XCTest — sole test framework

**Build/Dev:**

- XcodeGen — generates `Oak.xcodeproj` from `Oak/project.yml` (`just dev` regenerates)
- xcodebuild — build/test driver (via `just`)
- just — task runner (`justfile` at repo root)
- SwiftLint — linting (`--strict`)
- SwiftFormat — formatting (Swift 6.2 mode)

## Key Dependencies

**Critical:**

- Sparkle 2.9.4+ — auto-update framework; `SPUStandardUpdaterController` with EdDSA-signed appcast feed. Configured via `SPARKLE_PUBLIC_ED_KEY` build setting and `SUFeedURL` in `Info.plist`.

**Infrastructure:**

- None external. All other functionality uses Apple system frameworks only.

## Configuration

**Environment:**

- No runtime env vars required for normal operation
- `XCTestConfigurationFilePath` / `XCTestBundlePath` env vars detected in `AppDelegate.isRunningTests` to skip window creation during tests (`Oak/Oak/OakApp.swift:31`)

**Build:**

- `Oak/project.yml` — XcodeGen spec (bundle id `com.productsway.oak.app`, deployment target 13.0, Xcode 17.0)
- `Oak/Oak/Info.plist` — Sparkle keys, `LSUIElement`, version placeholders
- `.swiftlint.yml` — opt-in rules, line/file/function limits, custom `no_print_statements` rule
- `.swiftformat` — indent 4, maxwidth 120, `--self remove`, `--importgrouping testable-bottom`, `--header strip`
- `justfile` — `MARKETING_VERSION` derived from latest `v*` git tag (fallback `0.4.3`); `CURRENT_PROJECT_VERSION` from `git rev-list --count HEAD`

## Platform Requirements

**Development:**

- macOS with Xcode 17+, XcodeGen (`brew install xcodegen`), just, SwiftLint, SwiftFormat
- `just dev` to regenerate + build + run

**Production:**

- macOS 13.0+ Apple Silicon
- Distribution: direct DMG download via GitHub Releases, auto-update via Sparkle appcast, Homebrew Cask (`Casks/oak.rb`)
- Code signing + notarization required for distribution (CI builds unsigned: `CODE_SIGNING_ALLOWED=NO`)

---

_Stack analysis: 2026-07-26_
