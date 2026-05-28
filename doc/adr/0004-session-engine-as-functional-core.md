# 0004. Session Engine as Functional Core

Date: 2026-05-25

## Status

Accepted

## Context

`FocusSessionViewModel` had grown to 405 lines and conflated four concerns behind one interface:

1. The Focus Session finite state machine (`idle` → `running` → `paused` → `completed`)
2. Wall-clock timers (`Timer.scheduledTimer` for ticks; a second `Timer` for the auto-start countdown)
3. Side-effect orchestration (audio, notifications, completion sound, progress recording, completion-flash animation, auto-start scheduling)
4. SwiftUI publishing

The view model required six constructor collaborators (`PresetSettingsStore`, `AudioManager`, `ProgressManager`, `SessionCompletionNotifying`, `SessionCompletionSoundPlaying`, `currentDate: () -> Date`) to answer any behavioural question. Round-counting and day-rollover logic was duplicated between the view model and `ProgressManager` — the recent "refresh day rollover and reset rounds" fix had to touch both files.

The **Session Kind** of a session existed in three representations: `SessionState.running(isWorkSession: Bool)`, a private `isLongBreak: Bool` on the view model, and the `SessionType` enum used by `SessionRecord`.

Tests were constructing the full collaborator graph (`MockAudioManager`, `MockNotificationService`, `currentDate` closures) to verify pure FSM behaviour like "after 3 rounds the next break is long".

## Decision

Extract a pure `SessionEngine` as the functional core of Focus Session behaviour, with `FocusSessionViewModel` reduced to an imperative shell.

The engine is a **`struct`** with `mutating` event application:

```swift
struct SessionEngine {
    private(set) var state: SessionState
    private(set) var completedRounds: Int
    var nextSessionPreview: SessionType? { … }

    init(config: SessionConfig, calendar: Calendar = .current, now: Date)

    mutating func updateConfig(_ new: SessionConfig)
    mutating func setCurrentlyPlayingAudio(_ track: AudioTrack)
    mutating func apply(_ event: SessionEvent) -> [SessionIntent]
}
```

The engine **owns**:

- The `SessionState` FSM and its transitions
- Round counting and the Long Break decision
- Day-rollover-driven round reset (via an injected `Calendar`)
- The `lastPlayingAudioTrack` memory for audio resumption
- Duration math from `SessionConfig`
- Emission of `SessionIntent` values describing the side effects required

The engine **does not own**:

- Timers (the shell owns both the session ticking `Timer` and the auto-start countdown `Timer`)
- `AudioManager`, `NotificationService`, `ProgressManager`, `SessionCompletionSoundPlaying` (the shell holds these and executes intents against them)
- The 1.5s completion-flash flag or the auto-start countdown counter (purely visual timing, owned by the shell)
- `@Published` plumbing or any SwiftUI dependency
- Any direct subscription to `PresetSettingsStore` or `AudioManager` (the shell pushes updates via `updateConfig` and `setCurrentlyPlayingAudio`)

### State carries Session Kind

`SessionState` is rewritten to carry `SessionType` instead of `isWorkSession: Bool`. The private `isLongBreak: Bool` flag is deleted. The Session Kind has one representation across the FSM, progress recording, and notifications.

### Intents over delegate

The engine returns `[SessionIntent]` from each `apply(...)` call. The shell dispatches each intent to the appropriate service. This was chosen over a delegate protocol because:

- Side-effect order becomes explicit in the returned array
- Tests assert on intent arrays directly without any mock
- The engine has no reference-typed collaborators to reason about

### Time pushed in per event

Every `SessionEvent` carries `now: Date`. The engine has no `currentDate: () -> Date` closure and no shared clock. Tests advance time by passing different `Date` values to `tick`. The engine uses an injected `Calendar` (default `.current`) for day-rollover detection.

## Consequences

### Positive

- **Locality**: round tracking, Long Break decision, day rollover, and audio-memory rules concentrate in one ~200-line file with one test suite.
- **Leverage**: every behavioural question becomes a pure synchronous test — no mocks, no `MainActor`, no clock closures, no sleeps.
- The view model shrinks to a thin shell — timer plumbing, Combine subscriptions, and intent dispatch. Most of its remaining lines are glue, not logic.
- Session Kind has a single representation (`SessionType`).
- `SessionState` becomes self-describing — `kind` lives in the enum case, not a parallel field.

### Negative

- The engine imports `AudioTrack` (a small but real dependency on the audio model) because it owns `lastPlayingAudioTrack`.
- A `SessionConfig` snapshot must be kept in sync by the shell whenever `PresetSettingsStore` publishes — an extra Combine subscription.
- Day-rollover logic now lives in two places (`SessionEngine` and `ProgressManager`). Consolidating them under a shared `DayClock` is deferred until both modules are clean and the seam is real (per the "one adapter is a hypothetical seam" rule).

### Rejected alternatives

- **Engine as a `class` or `actor`**: rejected. Value semantics bulletproof tests, eliminate `[weak self]` ceremony, and avoid forcing the FSM into `async` when it has no concurrency to manage.
- **Delegate protocol for side effects**: rejected. Re-introduces the mock-graph problem that motivated the refactor and hides side-effect ordering.
- **Engine holds a `PresetSettingsStore` reference**: rejected. Forces the engine into `@MainActor` and Combine, defeating the purity.
- **Shell owns `lastPlayingAudioTrack`**: rejected for cohesion — every piece of session memory that survives across event boundaries should live in one place.
- **Shared `DayClock` seam introduced now** (the original Candidate 2): rejected. The view model and `ProgressManager` rollover triggers run on different cadences (user events vs. 60s polling); the seam is hypothetical until both modules are clean enough to share a real one.
