# Codebase Concerns

**Analysis Date:** 2026-02-15

## Tech Debt

**Deprecated UpdateChecker still in codebase:**
- Issue: Legacy `UpdateChecker` service is fully deprecated in favor of Sparkle but remains in the source tree with its own test file
- Files: `Oak/Oak/Services/UpdateChecker.swift`, `Oak/Tests/OakTests/UpdateCheckerTests.swift`
- Impact: Maintenance burden; developers may accidentally use it; ~157 lines of dead code plus ~140 lines of tests
- Fix approach: Remove both files entirely since Sparkle is the active update mechanism

**Singleton overuse via `static let shared`:**
- Issue: Multiple services use singletons (`PresetSettingsStore.shared`, `NotificationService.shared`, `SparkleUpdater.shared`, `NSScreenUUIDCache.shared`) making DI inconsistent — some paths use injected instances while others reference `.shared` directly
- Files: `Oak/Oak/Services/PresetSettingsStore.swift:7`, `Oak/Oak/Services/NotificationService.swift:13`, `Oak/Oak/Services/SparkleUpdater.swift:10`, `Oak/Oak/Views/NotchCompanionView.swift:6-7`
- Impact: `NotchCompanionView` creates its own `@StateObject` from `.shared` singletons (line 6-7) instead of receiving injected instances, creating parallel object graphs; hard to test in isolation
- Fix approach: Inject all dependencies through initializers consistently; remove `@StateObject private var notificationService` and `sparkleUpdater` from `NotchCompanionView` and pass from parent

**`completeSessionForTesting()` exposes internal method:**
- Issue: Test-only method `completeSessionForTesting()` is part of the production API surface
- Files: `Oak/Oak/ViewModels/FocusSessionViewModel.swift:295-297`
- Impact: Pollutes the public interface; could be called accidentally in production
- Fix approach: Use `@testable import` access or move to an extension in the test target

**Duplicate SettingsMenuView instantiation in OakApp:**
- Issue: `OakApp.body` has a duplicated `SettingsMenuView(...)` block — one for when `sparkleUpdater` exists, one as fallback — with identical frame/padding
- Files: `Oak/Oak/OakApp.swift:10-29`
- Impact: Any UI change to Settings must be duplicated in both branches
- Fix approach: Resolve `sparkleUpdater` before the view builder and use a single `SettingsMenuView` instantiation

**Empty `deinit` in ProgressManager:**
- Issue: `ProgressManager.deinit` contains only a comment placeholder ("Safety net for future resources")
- Files: `Oak/Oak/Services/ProgressManager.swift:94-96`
- Impact: Minor noise; no actual cleanup occurs
- Fix approach: Remove the empty deinit

## Known Bugs

**NoiseGenerator is not thread-safe but accessed from audio render thread:**
- Symptoms: Potential data races on `brownNoiseLast` and `rainSeed` properties when `AVAudioSourceNode` render callback fires on the audio thread while `NoiseGenerator` is accessed from `@MainActor` context
- Files: `Oak/Oak/Services/AudioManager.swift:237-276`
- Trigger: Start any generated ambient sound track (when no bundled file exists); the render callback runs on a real-time audio thread
- Workaround: Currently works because `NoiseGenerator` is only mutated from the render callback, but `AudioManager` is `@MainActor` and creates/replaces `NoiseGenerator` instances on main thread while callbacks may still fire

**Timer drift over long sessions:**
- Symptoms: Session duration may drift from wall-clock time over long focus sessions (50+ minutes)
- Files: `Oak/Oak/ViewModels/FocusSessionViewModel.swift:239-246`
- Trigger: Run a long focus session; `Timer.scheduledTimer` with 1-second interval accumulates drift because each tick decrements by 1 second regardless of actual elapsed time
- Workaround: Sessions are short enough that drift is typically <1 second, but edge cases exist

**US005Tests contain mostly trivially-passing assertions:**
- Symptoms: Tests like `testCompletionFeedbackDoesNotStealKeyboardFocus()` always pass with `XCTAssertTrue(... || true)` (line 92) — they don't actually test anything
- Files: `Oak/Tests/OakTests/US005Tests.swift:42,92`
- Trigger: Run tests — they always pass regardless of code changes
- Workaround: None; these tests provide false confidence

## Security Considerations

**Sparkle public ED key in `project.yml`:**
- Risk: The `SUPublicEDKey` is committed in plaintext in `project.yml`. While the public key is meant to be distributed, committing build configuration secrets in source creates a pattern that could lead to private key leaks
- Files: `Oak/project.yml:28`
- Current mitigation: This is a public key (verification only), not a private signing key
- Recommendations: Document clearly that only the public key is committed; ensure the private signing key is never in the repo

**Network entitlement is broad:**
- Risk: `com.apple.security.network.client` allows any outbound network connection, not just update checks
- Files: `Oak/Oak/Oak.entitlements:5-6`
- Current mitigation: App only makes requests to GitHub (appcast.xml, legacy update checker)
- Recommendations: Acceptable for current use; monitor if new network calls are added

**No App Sandbox entitlement:**
- Risk: App runs without macOS App Sandbox, giving it full filesystem and process access
- Files: `Oak/Oak/Oak.entitlements`
- Current mitigation: App is distributed outside the Mac App Store; notch window management requires non-sandboxed capabilities
- Recommendations: Consider adding sandbox if possible in future; document why it's unsandboxed

## Performance Bottlenecks

**Progress history grows unbounded:**
- Problem: `ProgressManager` stores all historical `ProgressData` records in UserDefaults with no pruning
- Files: `Oak/Oak/Services/ProgressManager.swift:15-29,32-39`
- Cause: Every session completion appends a new record; `loadRecords()` decodes the entire array; `recordSessionCompletion` sorts all records on every write
- Improvement path: Prune records older than 90 days; only keep daily aggregates for streak calculation

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

**AppDelegate deinit cleanup pattern:**
- Files: `Oak/Oak/OakApp.swift:72-77`
- Why fragile: `deinit` captures `notchWindowController` into a `Task { @MainActor in }` to call `cleanup()`, but `deinit` is not guaranteed to run on `@MainActor`, and the task may execute after the process is already terminating
- Safe modification: Rely on `applicationWillTerminate` for cleanup instead
- Test coverage: None for app lifecycle

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
- Migration plan: Sparkle is well-maintained and widely used; low risk. Fallback: the legacy `UpdateChecker` pattern (GitHub API) could be modernized if needed

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

**US005Tests are effectively no-ops:**
- What's not tested: Despite having 6 test methods, most use `XCTAssertTrue(... || true)` or test constant values — they verify nothing about actual session completion behavior
- Files: `Oak/Tests/OakTests/US005Tests.swift`
- Risk: Session completion animation and feedback could break without any test failing
- Priority: High — rewrite to actually test completion flow using `completeSessionForTesting()`

**ProgressManager streak calculation edge cases:**
- What's not tested: Timezone changes during streak, daylight saving transitions, records with 0 completed sessions in the middle of a streak
- Files: `Oak/Oak/Services/ProgressManager.swift:63-91`
- Risk: Streak could incorrectly reset or inflate across timezone boundaries
- Priority: Low — unlikely in practice but could confuse users

---
*Concerns audit: 2026-02-15*
