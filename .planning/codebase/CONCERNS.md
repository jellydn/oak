# Codebase Concerns

**Analysis Date:** 2026-02-13

## Tech Debt

**AudioManager strong self captures in audio render callbacks:**
- Issue: `AVAudioSourceNode` closures in `createBrownNoiseNode()`, `createRainNode()`, etc. capture `self` strongly without `[weak self]`. These are real-time audio render callbacks on the audio thread that hold a strong reference to `AudioManager`, preventing deallocation if the engine is not explicitly stopped.
- Files: `Oak/Oak/Services/AudioManager.swift:109-151`
- Impact: Potential retain cycle if `AudioManager` is deallocated before `stop()` is called; audio callbacks continue accessing deallocated state.
- Fix approach: Use `[weak self]` in all `AVAudioSourceNode` closures and guard against nil.

**Duplicate audio stop on session completion:**
- Issue: `completeSession()` calls `audioManager.stop()` inside the `if isWorkSession` branch and again unconditionally at line 189. The break-session branch also calls `stop()` before the unconditional call.
- Files: `Oak/Oak/ViewModels/FocusSessionViewModel.swift:174-189`
- Impact: Redundant calls; no crash but indicates unclear intent. The conditional stop in the `else` branch (break complete) is immediately followed by an unconditional stop, making it dead code.
- Fix approach: Remove the conditional `audioManager.stop()` calls and keep only the unconditional one, or clarify the intent with distinct behavior per session type.

**No `deinit` on any class:**
- Issue: `AudioManager`, `ProgressManager`, `FocusSessionViewModel`, `NotchWindowController`, and `AppDelegate` have no `deinit` implementations. Cleanup relies entirely on explicit `cleanup()` calls.
- Files: All classes in `Oak/Oak/Services/`, `Oak/Oak/ViewModels/`, `Oak/Oak/Views/`
- Impact: If `cleanup()` is missed, timers and audio engines leak. `NotchWindowController.cleanup()` accesses `rootView.viewModel` through `NSHostingView` casting, which is fragile.
- Fix approach: Add `deinit` as a safety net that calls `cleanup()` or invalidates timers/engines.

**`print()` for error logging in production code:**
- Issue: `AudioManager` uses `print()` for error logging (lines 30, 105) instead of `os.log` as specified in the project conventions.
- Files: `Oak/Oak/Services/AudioManager.swift:30,105`
- Impact: Errors are invisible in production (no system log integration). Inconsistent with `UpdateChecker` which correctly uses `Logger`.
- Fix approach: Replace `print()` with `Logger` from the `os` framework.

**NotchWindowControllerTests excluded from test target:**
- Issue: `project.yml` explicitly excludes `NotchWindowControllerTests.swift` from the `OakTests` target (line 32), yet the file exists and contains 19 test methods.
- Files: `Oak/project.yml:32`, `Oak/Tests/OakTests/NotchWindowControllerTests.swift`
- Impact: Window controller tests never run in CI or local test suites. Regressions in window positioning/expansion go undetected.
- Fix approach: Remove the exclusion or fix whatever issue caused it to be excluded (likely UI dependency issues in headless CI).

**Hardcoded UserDefaults key shared between production and tests:**
- Issue: `ProgressManager` uses `UserDefaults.standard` with key `"progressHistory"`. Tests directly manipulate `UserDefaults.standard` with the same key (US006Tests), meaning tests pollute the user's actual app data if run on a development machine.
- Files: `Oak/Oak/Services/ProgressManager.swift:8`, `Oak/Tests/OakTests/US006Tests.swift:11,17`
- Impact: Test isolation failure; tests can corrupt real progress data; parallel test runs can interfere with each other.
- Fix approach: Inject `UserDefaults` (use a custom suite or in-memory store for tests), similar to how `UpdateChecker` already accepts `userDefaults` via DI.

## Known Bugs

**`rainSeed` accumulates without bound:**
- Symptoms: `rainSeed` increments by 0.01 per audio sample (~44100/sec) and never resets. After ~13 hours of continuous playback, it exceeds `Float.greatestFiniteMagnitude` range for `sin()` accuracy, causing degraded audio quality. After much longer, potential `Float` overflow.
- Files: `Oak/Oak/Services/AudioManager.swift:176-181`
- Trigger: Leave rain ambient sound playing for extended periods.
- Workaround: Restart rain audio periodically. Fix by wrapping `rainSeed` with modulo `2 * Float.pi`.

**`brownNoiseLast` state not reset between plays:**
- Symptoms: When stopping and restarting brown noise, `brownNoiseLast` retains its previous value, causing a potential audio pop/glitch at the start of playback since the waveform doesn't start from zero.
- Files: `Oak/Oak/Services/AudioManager.swift:167-173`
- Trigger: Stop brown noise, then immediately play it again.
- Workaround: None. Fix by resetting `brownNoiseLast = 0` in `generateAmbientSound()` before creating the new engine.

**Streak calculation depends on record sort order:**
- Symptoms: `calculateStreak()` iterates records assuming they are sorted by date descending, which `recordSessionCompletion()` does. But `loadRecords()` decodes from UserDefaults without re-sorting, so if data is manually edited or corrupted, streak calculation silently produces wrong results.
- Files: `Oak/Oak/Services/ProgressManager.swift:57-84`
- Trigger: Corrupted or manually edited UserDefaults data.
- Workaround: None needed in normal usage. Fix by sorting records in `calculateStreak()` before iterating.

## Security Considerations

**Empty entitlements file:**
- Risk: `Oak.entitlements` is an empty dict. The app uses `AVAudioEngine` (microphone-adjacent API), network access (GitHub API for updates), and `UserDefaults` persistence. Missing sandbox entitlements mean the app runs unsandboxed, which is a blocker for Mac App Store distribution.
- Files: `Oak/Oak/Oak.entitlements`
- Current mitigation: App distributed via GitHub releases (no App Store).
- Recommendations: Add App Sandbox entitlement with `com.apple.security.network.client` for update checks. Add audio entitlement if needed. Consider signing for notarization.

**GitHub API requests without rate limit handling:**
- Risk: `UpdateChecker` makes unauthenticated GitHub API requests. GitHub's rate limit for unauthenticated requests is 60/hour per IP. If many users share an IP (corporate networks), update checks fail silently.
- Files: `Oak/Oak/Services/UpdateChecker.swift:47-74`
- Current mitigation: Only checks on launch; 24-hour cooldown between prompts.
- Recommendations: Handle 403/429 responses gracefully. Consider using GitHub's conditional requests (If-None-Match/ETag) to reduce rate limit consumption.

**No input validation on GitHub API response:**
- Risk: `UpdateChecker` trusts the decoded `htmlURL` from GitHub's API response and opens it directly with `NSWorkspace.shared.open()`. A MITM attack could redirect users to a malicious URL.
- Files: `Oak/Oak/Services/UpdateChecker.swift:109-111`
- Current mitigation: HTTPS transport.
- Recommendations: Validate that `htmlURL` host is `github.com` before opening.

## Performance Bottlenecks

**Procedural audio generation on main thread concern:**
- Problem: `AudioManager` is `@MainActor` but `AVAudioSourceNode` render callbacks execute on the real-time audio thread. The `@MainActor` annotation may cause Swift concurrency to attempt actor-hopping in the render callback, which is forbidden on the real-time audio thread (no locks, no allocations).
- Files: `Oak/Oak/Services/AudioManager.swift:5-6,109-151`
- Cause: Mismatch between `@MainActor` class annotation and real-time audio thread requirements. The `self.fillOutputBuffer` and `self.generateX()` calls inside the render callback implicitly reference `@MainActor`-isolated state.
- Improvement path: Move audio generation state (`brownNoiseLast`, `rainSeed`) and methods to a non-isolated helper class or use `nonisolated` methods. Alternatively, use `@preconcurrency` or `Sendable` conformance carefully.

**ProgressManager sorts all records on every session completion:**
- Problem: `recordSessionCompletion()` sorts the entire record array after every session. With hundreds of historical records, this is O(n log n) per completion.
- Files: `Oak/Oak/Services/ProgressManager.swift:26`
- Cause: Full sort instead of insertion sort or maintaining sorted order.
- Improvement path: Insert new records at the correct position (binary search) or prepend since new records always have the latest date.

## Fragile Areas

**NotchWindowController cleanup via NSHostingView casting:**
- Files: `Oak/Oak/Views/NotchWindowController.swift:23`
- Why fragile: `cleanup()` casts `window?.contentView` to `NSHostingView<NotchCompanionView>` to access `rootView.viewModel.cleanup()`. This breaks if the view hierarchy changes, if `NotchCompanionView` gains generic parameters, or if SwiftUI internals change how `rootView` works.
- Safe modification: Store a direct reference to the `FocusSessionViewModel` or `NotchCompanionView` in `NotchWindowController` instead of reaching through the view hierarchy.
- Test coverage: `testCleanupReleasesViewModelResources` only asserts `XCTAssertNoThrow` — it doesn't verify that timer/audio resources are actually released.

**NotchCompanionView is a 443-line monolith:**
- Files: `Oak/Oak/Views/NotchCompanionView.swift`
- Why fragile: Contains 3 distinct views (`NotchCompanionView`, `AudioMenuView`, `ProgressMenuView`) in one file. `NotchCompanionView` alone has 12+ computed properties and complex state management with multiple `@State` variables. Changes to layout constants risk breaking the notch alignment.
- Safe modification: Extract `AudioMenuView` and `ProgressMenuView` to separate files. Extract layout constants to a shared configuration.
- Test coverage: No direct unit tests for `AudioMenuView` or `ProgressMenuView` behavior (only structural instantiation tests).

**Hardcoded layout constants duplicated across files:**
- Files: `Oak/Oak/Views/NotchCompanionView.swift:13-18`, `Oak/Oak/Views/NotchWindowController.swift:5-7`
- Why fragile: `collapsedWidth` (132 vs 144), `expandedWidth` (360 vs 372), and `notchHeight` (33) are defined independently in both files with slightly different values (the window adds padding). If either changes without updating the other, the UI breaks.
- Safe modification: Define shared layout constants in a single source of truth.
- Test coverage: `NotchWindowControllerTests` is excluded from the test target.

## Scaling Limits

**UserDefaults for progress persistence:**
- Current capacity: Works fine for months of daily records (a few KB).
- Limit: UserDefaults is not designed for large datasets. After years of use (~1000+ records), serialization/deserialization on every session completion becomes noticeable. UserDefaults has a practical limit of ~512KB on some systems.
- Scaling path: Migrate to SQLite (via SwiftData/CoreData) or a simple JSON file for historical records. Keep only recent data in UserDefaults.

**Single-display assumption:**
- ~~Current capacity: Works correctly on the primary display.~~ **RESOLVED**: Now detects and uses the built-in display with notch.
- ~~Limit: `NSScreen.main` is used for window positioning. On multi-monitor setups, the notch window always appears on the primary display, which may not have a notch (external monitors).~~ **RESOLVED**: Uses `NSScreen.auxiliaryTopLeftArea` to detect notch on macOS 12+.
- Implementation: The window controller now observes `NSApplication.didChangeScreenParametersNotification` and automatically repositions the window when display configuration changes.

## Dependencies at Risk

**No external dependencies (SPM or CocoaPods):**
- Risk: Low dependency risk. However, the project uses both `Package.swift` (SPM) and `project.yml` (XcodeGen) for project configuration. `Package.swift` defines Oak as an executable target but doesn't include the test target. The actual build/test workflow relies on `project.yml` + XcodeGen.
- Impact: `swift build` and `swift test` via SPM won't work for the full project (no test target). Developers must use `xcodegen generate` + Xcode.
- Migration plan: Either commit fully to SPM (add test target to Package.swift) or remove Package.swift to avoid confusion.

**XcodeGen dependency for project generation:**
- Risk: `project.yml` requires XcodeGen to regenerate the `.xcodeproj`. If XcodeGen introduces breaking changes or is abandoned, project regeneration fails.
- Impact: Cannot regenerate Xcode project without XcodeGen.
- Migration plan: Consider migrating to native SPM with Xcode workspace, or pin XcodeGen version.

## Missing Critical Features

~~**No graceful handling of display changes:**~~ **RESOLVED**
- ~~Problem: If the user connects/disconnects an external display, or if `NSScreen.main` changes, the notch window position is not recalculated.~~
- ~~Blocks: Proper multi-monitor support; window may become invisible or mispositioned after display configuration changes.~~
- Solution: Implemented `NSApplication.didChangeScreenParametersNotification` observer that automatically recalculates window position when displays are connected/disconnected. The window now detects the built-in display with notch using `NSScreen.auxiliaryTopLeftArea`.

**No app quit mechanism beyond right-click context menu:**
- Problem: The only way to quit is via the right-click context menu on the notch window or Force Quit. There's no menu bar icon, no Dock icon (`LSUIElement: true`), and no keyboard shortcut.
- Blocks: Discoverability; users may not know how to quit the app.

**Settings menu item is disabled:**
- Problem: The right-click context menu has a "Settings..." item that is explicitly disabled (`action: nil, isEnabled: false`).
- Blocks: Users cannot configure any preferences (volume default, auto-start behavior, etc.).

## Test Coverage Gaps

**AudioManager has no dedicated test file:**
- What's not tested: Audio engine lifecycle (start/stop/restart), volume control under playback, track switching during active playback, memory cleanup of audio nodes, behavior when audio hardware is unavailable.
- Files: `Oak/Oak/Services/AudioManager.swift` (201 lines, 0 dedicated tests)
- Risk: Audio regressions go undetected. The strong `self` capture bug and `rainSeed` overflow are examples of issues tests would catch.
- Priority: High

**Timer-driven state transitions untested:**
- What's not tested: The `tick()` method that decrements the timer, `completeSession()` behavior, work-to-break transitions, progress recording on completion. Tests only verify immediate state changes (start/pause/resume) but not time-based progression.
- Files: `Oak/Oak/ViewModels/FocusSessionViewModel.swift:164-200`
- Risk: Timer bugs, off-by-one errors in remaining seconds, incorrect progress recording (e.g., the `durationMinutes` calculation divides by 60 which truncates partial minutes).
- Priority: High

**UpdateChecker has no tests:**
- What's not tested: Version comparison logic, URL construction, cooldown behavior, GitHub API response parsing, error handling for network failures.
- Files: `Oak/Oak/Services/UpdateChecker.swift` (135 lines, 0 tests)
- Risk: Update prompts may fire incorrectly, version comparison may fail for pre-release versions (e.g., "1.0.0-beta.1"), cooldown logic untested.
- Priority: Medium

**ProgressManager streak calculation edge cases:**
- What's not tested: Multi-day streaks (tests acknowledge they "can't easily simulate historical data"), streak behavior across timezone changes, streak reset after missed day (test just asserts `true`).
- Files: `Oak/Tests/OakTests/US006Tests.swift:37-84`
- Risk: Streak count may be wrong across DST transitions or for users who travel across timezones. The streak algorithm has an off-by-one risk if records have times that don't align with `startOfDay`.
- Priority: Medium

**No UI/integration tests:**
- What's not tested: Actual SwiftUI view rendering, notch window positioning on real screens, popover behavior for audio/progress menus, expand/collapse animation, right-click context menu.
- Files: All views in `Oak/Oak/Views/`
- Risk: Visual regressions, layout issues on different screen sizes, broken user interactions.
- Priority: Low (acceptable for MVP)

---
*Concerns audit: 2026-02-13*
