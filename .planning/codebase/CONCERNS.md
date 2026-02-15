# Codebase Concerns

**Analysis Date:** 2026-02-15
**Last Updated:** 2026-02-15

## Tech Debt

**Singleton overuse via `static let shared`:**
- Issue: Multiple services use singletons (`PresetSettingsStore.shared`, `NotificationService.shared`, `SparkleUpdater.shared`, `NSScreenUUIDCache.shared`) making DI inconsistent — some paths use injected instances while others reference `.shared` directly
- Files: `Oak/Oak/Services/PresetSettingsStore.swift:7`, `Oak/Oak/Services/NotificationService.swift:13`, `Oak/Oak/Services/SparkleUpdater.swift:10`, `Oak/Oak/Views/NotchCompanionView.swift:6-7`
- Impact: `NotchCompanionView` creates its own `@StateObject` from `.shared` singletons (line 6-7) instead of receiving injected instances, creating parallel object graphs; hard to test in isolation
- Fix approach: Inject all dependencies through initializers consistently; remove `@StateObject private var notificationService` and `sparkleUpdater` from `NotchCompanionView` and pass from parent

## Known Bugs

None currently tracked.

## Security Considerations

**Sparkle public ED key in `project.yml`:**
- Risk: The `SUPublicEDKey` is committed in plaintext in `project.yml`. While the public key is meant to be distributed, committing build configuration secrets in source creates a pattern that could lead to private key leaks
- Files: `Oak/project.yml:28`
- Current mitigation: This is a public key (verification only), not a private signing key
- Recommendations: Document clearly that only the public key is committed; ensure the private signing key is never in the repo

**Network entitlement is broad:**
- Risk: `com.apple.security.network.client` allows any outbound network connection, not just update checks
- Files: `Oak/Oak/Oak.entitlements:5-6`
- Current mitigation: App only makes requests to GitHub (appcast.xml for Sparkle updates)
- Recommendations: Acceptable for current use; monitor if new network calls are added

**No App Sandbox entitlement:**
- Risk: App runs without macOS App Sandbox, giving it full filesystem and process access
- Files: `Oak/Oak/Oak.entitlements`
- Current mitigation: App is distributed outside the Mac App Store; notch window management requires non-sandboxed capabilities
- Recommendations: Consider adding sandbox if possible in future; document why it's unsandboxed

## Performance Bottlenecks

**NSScreen UUID cache rebuilds on every display change:**
- Problem: `NSScreenUUIDCache.rebuildCache()` iterates all screens and calls `CGDisplayCreateUUIDFromDisplayID` on each notification
- Files: `Oak/Oak/Extensions/NSScreen+UUID.swift:76-85`
- Cause: Rebuilds entire cache even for minor screen parameter changes (brightness, resolution)
- Improvement path: Minor concern for typical 1-3 displays; acceptable but could debounce

**Audio engine recreation on every track change:**
- Problem: `generateAmbientSound()` calls `stop()` (tears down entire audio engine) then builds a new one for each track switch
- Files: `Oak/Oak/Services/AudioManager.swift:111-166`
- Cause: No reuse of `AVAudioEngine` instance; full teardown/rebuild cycle
- Improvement path: Reuse the audio engine and swap only the source node

## Fragile Areas

**NotchWindowController frame update scheduling:**
- Files: `Oak/Oak/Views/NotchWindowController.swift:121-152`
- Why fragile: Complex coalescing logic with `pendingExpandedState`, `pendingForceReposition`, `pendingTargetOverride`, and `isFrameUpdateScheduled` — race-prone if multiple `DispatchQueue.main.async` calls overlap; the `isApplyingFrameChange` guard (line 160) prevents re-entrant frame changes but makes debugging difficult
- Safe modification: Always test with display target switching and screen connect/disconnect; verify frame updates coalesce correctly
- Test coverage: `NotchWindowControllerTests+WindowBehavior.swift` covers basic expand/collapse but not concurrent rapid toggles

**NotchCompanionView view extension split:**
- Files: `Oak/Oak/Views/NotchCompanionView.swift`, `Oak/Oak/Views/NotchCompanionView+Controls.swift`, `Oak/Oak/Views/NotchCompanionView+InsideNotch.swift`, `Oak/Oak/Views/NotchCompanionView+StandardViews.swift`
- Why fragile: View logic is split across 4 files with shared `@State` properties; `isExpandedByToggle`, `showAudioMenu`, `lastReportedExpansion` are all defined in the main file but mutated from extensions; changing state variable names requires updates across all 4 files
- Safe modification: Search all `NotchCompanionView` extensions when changing any `@State` property
- Test coverage: No direct view tests; only ViewModel-level testing via US00x tests

## Scaling Limits

**UserDefaults for progress data:**
- Current capacity: Works well for daily records over months
- Limit: UserDefaults is not designed for large datasets; at ~1 year of daily records (~365 entries), serialization/deserialization adds latency; at ~5+ years, could impact app launch time
- Scaling path: Migrate to SQLite or SwiftData for progress history if retention grows; add data pruning

**Single-window architecture:**
- Current capacity: One notch window per app instance
- Limit: Cannot show on multiple displays simultaneously; no support for multiple concurrent focus sessions
- Scaling path: Would require multi-window controller architecture if multi-display support is needed

## Dependencies at Risk

**Sparkle 2.6.4+:**
- Risk: External dependency for auto-updates; if Sparkle is abandoned or has breaking changes, update mechanism stops working
- Impact: Users won't receive automatic updates; manual download required
- Migration plan: Sparkle is well-maintained and widely used; low risk. Fallback: a simple GitHub API release checker could be built if needed

## Missing Critical Features

**No keyboard shortcuts:**
- Problem: No global or local keyboard shortcuts for start/pause/resume/reset
- Blocks: Power users cannot operate the timer without mouse interaction with the notch UI

**No auto-start next interval:**
- Problem: Auto-start next interval defaults to OFF and there is no toggle to enable it
- Blocks: Users who want continuous Pomodoro cycles must manually click "Next" after each interval

**No data export/backup:**
- Problem: Progress data is only in local UserDefaults with no export capability
- Blocks: Users cannot migrate data to a new machine or back up their focus history

**No accessibility support:**
- Problem: No VoiceOver labels, accessibility identifiers, or accessibility traits on custom controls
- Blocks: Accessibility users cannot interact with the notch companion UI

## Test Coverage Gaps

**AudioManager has zero test coverage:**
- What's not tested: Audio playback, track selection, volume control, engine lifecycle, generated noise output
- Files: `Oak/Oak/Services/AudioManager.swift`
- Risk: Audio bugs (silence, crashes, resource leaks) could ship undetected; the `AVAudioEngine`/`AVAudioSourceNode` lifecycle is complex
- Priority: Medium — audio is a core feature but hard to unit test without mocking AVFoundation

**NotchCompanionView UI behavior untested:**
- What's not tested: Expansion toggle, popover display, animation triggers, inside-notch vs. standard layout switching
- Files: `Oak/Oak/Views/NotchCompanionView.swift`, `Oak/Oak/Views/NotchCompanionView+Controls.swift`, `Oak/Oak/Views/NotchCompanionView+InsideNotch.swift`, `Oak/Oak/Views/NotchCompanionView+StandardViews.swift`
- Risk: UI regressions in compact/expanded modes or notch detection logic
- Priority: Medium — view layer is verified manually but automated coverage would catch regressions

**SettingsMenuView binding logic untested:**
- What's not tested: Stepper bindings, display target picker sync, countdown mode picker, always-on-top toggle persistence from UI
- Files: `Oak/Oak/Views/SettingsMenuView.swift:312-401`
- Risk: Settings changes may not propagate correctly to `PresetSettingsStore`
- Priority: Low — covered indirectly by `PresetSettingsStore` tests but UI binding bugs possible

**ProgressManager streak calculation edge cases:**
- What's not tested: Timezone changes during streak, daylight saving transitions, records with 0 completed sessions in the middle of a streak
- Files: `Oak/Oak/Services/ProgressManager.swift:63-91`
- Risk: Streak could incorrectly reset or inflate across timezone boundaries
- Priority: Low — unlikely in practice but could confuse users

## Resolved

- ~~Deprecated UpdateChecker still in codebase~~ — Removed `UpdateChecker.swift` and `UpdateCheckerTests.swift` (~300 lines deleted)
- ~~`completeSessionForTesting()` exposes internal method~~ — Removed wrapper; made `completeSession()` internal, accessible via `@testable import`
- ~~Duplicate SettingsMenuView instantiation in OakApp~~ — Collapsed if/else to single instantiation with nil-coalescing `??`
- ~~Empty `deinit` in ProgressManager~~ — Removed placeholder deinit
- ~~Timer drift over long sessions~~ — Switched from decrement-by-1 to wall-clock `Date`-based remaining time calculation
- ~~US005Tests are effectively no-ops~~ — Rewrote 6 tests with real assertions testing completion state, rounds, and session type transitions
- ~~NoiseGenerator thread safety~~ — Made generator a local variable captured by render closures; marked `@unchecked Sendable`; no shared mutable state (#66)
- ~~AppDelegate deinit cleanup pattern~~ — Removed fragile `deinit`; `applicationWillTerminate` already handles cleanup (#73)
- ~~Progress history grows unbounded~~ — Added 90-day retention pruning via `pruneOldRecords()` on each write (#71)

---
*Concerns audit: 2026-02-15*
