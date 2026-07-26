# Codebase Concerns

**Analysis Date:** 2026-07-26

## Tech Debt

**`SettingsMenuView` size:**

- Issue: 433 lines — within 100 of the SwiftLint file-length warning (500) and approaching the error (1000). Largest source file.
- Files: `Oak/Oak/Views/SettingsMenuView.swift`
- Impact: Harder to navigate; risk of growing past the lint warning. `PresetEditorView` was already extracted (PR #138) — further extraction (notification settings, update settings already split into separate views) is in progress but the orchestrating container is still large.
- Fix approach: Continue extracting sections into sub-views (e.g. a `DisplaySettingsView`, `BehaviorSettingsView`) following the `PresetEditorView` pattern.

**`FocusSessionViewModel.completeSession()` length:**

- Issue: ~50 lines — at the SwiftLint `function_body_length` warning threshold (50). Mixes round tracking, progress recording, notifications, audio, sound, state transition, and auto-start scheduling.
- Files: `Oak/Oak/ViewModels/FocusSessionViewModel.swift:319`
- Impact: Hard to unit-test each concern in isolation; high churn risk.
- Fix approach: Extract `recordCompletion()`, `playCompletionSoundIfNeeded()`, `scheduleAutoStartIfNeeded()` helpers.

**`FocusSessionViewModel` overall size:**

- Issue: 373 lines — second-largest non-view file. Holds session control + derived display state + audio coordination + round tracking. Type body warn threshold is 300 (already exceeded).
- Files: `Oak/Oak/ViewModels/FocusSessionViewModel.swift`
- Impact: Single point of mutation; many `@Published` properties and collaborators.
- Fix approach: Consider extracting a `SessionRoundsTracker` (round counting / long-break logic) and moving derived display state into a dedicated `SessionDisplayState` value type.

## Known Bugs

No open bugs found in the codebase. No `TODO`/`FIXME`/`HACK`/`XXX` comments exist in `Oak/Oak` (verified via ripgrep — 0 matches). `CONCERNS.md` was previously updated (commit `488af4a`) to reflect resolved concerns.

## Security Considerations

**Sparkle EdDSA key in project.yml:**

- Risk: `SPARKLE_PUBLIC_ED_KEY` is committed in `Oak/project.yml` — but this is a _public_ key by design (Sparkle verifies update signatures with the private key kept outside the repo). Not a secret leak.
- Files: `Oak/project.yml`, `Oak/Oak/Info.plist`
- Current mitigation: `SparkleUpdater.hasValidPublicEDKey` guards against placeholder `$(...)` values at runtime; CI `update-appcast.yml` signs with the private key from secrets.
- Recommendations: None — current setup is correct for Sparkle.

**No network input validation:**

- Risk: `SparkleUpdater.fetchLatestFeedVersion` fetches `appcast.xml` and parses with `NSRegularExpression`. The feed is trusted (EdDSA-signed at the Sparkle layer), so parser input is attacker-controlled only if GitHub/raw.githubusercontent is compromised.
- Files: `Oak/Oak/Services/SparkleUpdater.swift:181`, `AppcastVersionParser`
- Current mitigation: Sparkle's signature verification is the real gate; `AppcastVersionParser` only extracts a version string for preflight logging.
- Recommendations: None for MVP.

## Performance Bottlenecks

**Procedural audio render callbacks:**

- Problem: `NoiseGenerator` generates one sample per call inside `AVAudioSourceNode` render block, looping per-sample across the buffer (`AudioManager.fillOutputBuffer`).
- Files: `Oak/Oak/Services/NoiseGenerator.swift`, `Oak/Oak/Services/AudioManager.swift:250-317`
- Cause: Per-sample `Float.random(in:)` and `sin(...)` calls in the audio render thread. Correct but not optimized.
- Improvement path: Pre-generate a noise buffer and loop it, or vectorize sample generation. Only matters if CPU profiling shows audio thread pressure — bundled `.m4a` tracks are the primary path and bypass this entirely.

**`ProgressManager` loads all records on every operation:**

- Problem: `recordSessionCompletion`, `loadProgress`, `allRecords` each call `loadRecords()` which decodes the full `[ProgressData]` array from UserDefaults.
- Files: `Oak/Oak/Services/ProgressManager.swift:92`
- Cause: UserDefaults-backed storage with no in-memory cache beyond `dailyStats`.
- Improvement path: Acceptable for 90-day retention (bounded). If retention grows, cache `allRecords` and invalidate on write.

## Fragile Areas

**`NotchWindowController` frame-update coalescing:**

- Files: `Oak/Oak/Views/NotchWindowController.swift:144` (`requestFrameUpdate`, `setExpanded`)
- Why fragile: Uses `isApplyingFrameChange` / `isFrameUpdateScheduled` flags + `DispatchQueue.main.async` coalescing + `pendingExpandedState`/`pendingForceReposition`/`pendingTargetOverride` buffers. Reentrancy and ordering are subtle; a missed `setFrame` could leave the window in the wrong position after display changes.
- Safe modification: Add a regression test in `NotchWindowControllerTests+WindowBehavior` for any change; preserve the `forceReposition` semantics.
- Test coverage: `NotchWindowControllerTests+WindowBehavior` exists but exercises high-level behavior, not the coalescing state machine directly.

**View-update safety in `NotchCompanionView`:**

- Files: `Oak/Oak/Views/NotchCompanionView.swift:109`, `:116`
- Why fragile: AGENTS.md explicitly warns against publishing from view updates (`onChange` → sync `viewModel.update`). `NotchCompanionView` uses `DispatchQueue.main.async` for `onExpansionChanged` (`:345`) — the correct pattern — but `onChange(of: viewModel.isSessionComplete)` drives `animateCompletion`/`showConfetti` directly. This is safe (local `@State` mutation) but the boundary between "safe local state" and "publishing from view update" must be maintained carefully.
- Safe modification: Keep `@State` mutations local; never call `viewModel` mutation methods directly from `onChange`/`onAppear` — dispatch to main async.
- Test coverage: `NotchCompanionViewTests+SessionState` covers state-driven content; no test for the animation/confetti timing.

**`KeyboardShortcutService` event monitor lifecycle:**

- Files: `Oak/Oak/Services/KeyboardShortcutService.swift:105`
- Why fragile: A code comment documents that starting `NSEvent.addLocalMonitorForEvents` in `init()` (before the app launches) "corrupts the event monitor chain and freezes the UI." Monitors must start via `load()` from `applicationDidFinishLaunching`. Global monitor runs on a background thread and dispatches to `@MainActor` via `Task`.
- Safe modification: Never call `startLocalMonitor`/`startGlobalMonitor` from `init`; always via `load()`/`stop()` pairs. Preserve `removeMonitor` in `deinit`.
- Test coverage: `KeyboardShortcutService` config persistence is tested; event monitor behavior is not (hard to test without real events).

## Scaling Limits

**UserDefaults progress storage:**

- Current capacity: 90-day rolling window of `ProgressData` records (one per day, each with a `[SessionRecord]`).
- Limit: UserDefaults is loaded into memory at launch; unbounded growth would degrade launch time. 90-day retention + `pruneOldRecords` bounds this.
- Scaling path: For multi-year history, migrate to SQLite/Core Data or a JSON file on disk. Export/import already exists (`ProgressManager.exportJSON/exportCSV/importRecords`) as a bridge.

**Single-window, single-session:**

- Current capacity: One focus session at a time, one notch window.
- Limit: By design (MVP constraint — notch-only UI, no multi-window).
- Scaling path: Not applicable within MVP scope.

## Dependencies at Risk

**Sparkle:**

- Risk: Third-party dependency for auto-update. Pinned `from: 2.9.4` (allows minor/patch upgrades within 2.x).
- Impact: If Sparkle breaks semver or drops macOS 13 support, auto-update breaks.
- Migration plan: Sparkle is the de-facto macOS auto-update standard; no realistic alternative. Keep within the 2.x line; track Sparkle release notes for macOS-deployment-target changes.

## Missing Critical Features

None within the stated MVP scope (see `tasks/prd-macos-focus-companion-app.md` and `AGENTS.md` MVP Constraints). The `.changeset/` directory lists pending features (`detailed-session-timeline.md`, `pause-audio-on-pause.md`) — these are planned, not missing.

## Test Coverage Gaps

**`NotchWindowController` frame coalescing state machine:**

- What's not tested: The `requestFrameUpdate`/`setExpanded` coalescing logic with `pendingExpandedState`/`pendingForceReposition`/`pendingTargetOverride` buffering and `isApplyingFrameChange` reentrancy guard.
- Files: `Oak/Oak/Views/NotchWindowController.swift:144-218`
- Risk: A regression could leave the window mispositioned after display changes or rapid expand/collapse.
- Priority: Medium — high-level window behavior is tested; the coalescing internals are not.

**`KeyboardShortcutService` event handling:**

- What's not tested: `handleKeyEvent`/`handleGlobalKeyEvent` matching against `KeyEquivalent`, modifier-flag intersection, Escape keyCode 53 special-case, global monitor thread dispatch.
- Files: `Oak/Oak/Services/KeyboardShortcutService.swift:177-221`
- Risk: A regression could silently break hotkeys (toggle/reset).
- Priority: Medium — config persistence is tested; event matching is not.

**`AudioManager` real `AVAudioEngine` path:**

- What's not tested: Bundled-track playback and procedural `AVAudioSourceNode` rendering use real AVFoundation. Tests inject `MockTestAudioEngine` to avoid hardware. The real `AudioEngineAdapter` is only exercised by manual run.
- Files: `Oak/Oak/Services/AudioManager.swift`
- Risk: A regression in `playBundledTrack`/`generateAmbientSound`/`fillOutputBuffer` would only surface at runtime.
- Priority: Low — audio is best validated manually; the mock covers state transitions.

**Animation/confetti timing in `NotchCompanionView`:**

- What's not tested: The 1.5s completion reset, confetti `DispatchQueue.main.asyncAfter` lifecycle, `animateCompletion` spring animation.
- Files: `Oak/Oak/Views/NotchCompanionView.swift:116-134`
- Risk: Visual-only regressions; no functional impact.
- Priority: Low.

---

_Concerns audit: 2026-07-26_
