# Oak — Domain Glossary

## Focus Session

A timed interval of focused work or rest. The core unit of user activity. A session has a type (work or break), a duration, and a state within its lifecycle.

## Session State

The lifecycle stage of a focus session:

| Term | Definition |
| --- | --- |
| **Idle** | No session active; the app is ready to start a new one. |
| **Running** | A session is actively counting down. |
| **Paused** | A session was running but has been temporarily suspended; remaining time is preserved. |
| **Completed** | A session reached zero remaining time naturally (not cancelled). |

Transitions: idle → running → paused → running → completed → (auto-start) → running → ... → idle.

## Session Type (also Round)

The category of a focus session:

| Term | Definition |
| --- | --- |
| **Work Session** (Focus) | A timed interval dedicated to deep work. Counts toward daily progress and streaks. |
| **Short Break** | A brief rest interval between work sessions (default: 5 min). |
| **Long Break** | An extended rest interval triggered after a configurable number of consecutive work sessions (default: 4 rounds, 15–20 min). A long break resets the round counter. |

## Preset

A named pair of work and break durations:

| Term                    | Definition                                              |
| ----------------------- | ------------------------------------------------------- |
| **Short Preset** (25/5) | 25-minute work sessions with 5-minute breaks (default). |
| **Long Preset** (50/10) | 50-minute work sessions with 10-minute breaks.          |

Durations are user-configurable within reasonable bounds.

## Round

A completed work session. Rounds are tracked per day and reset after a long break or at the start of a new day. The round counter determines when a long break is triggered (default: after 4 consecutive work sessions).

## Auto-Start Next Interval

When enabled, the next session (break → work or work → break) begins automatically after a 10-second countdown. Default: **off**.

## Progress

Daily and historical tracking data:

| Term | Definition |
| --- | --- |
| **Focus Minutes** | Total minutes spent in completed work sessions on a given day. |
| **Completed Sessions** | Number of completed work sessions on a given day. |
| **Streak** | Consecutive days with at least one completed work session. Calculated backward from today. |
| **Session Record** | A persisted entry for a single completed session (type, start time, end time, duration). |
| **Day** | A calendar day in the local timezone (midnight-to-midnight). |

## Ambient Audio

Background sound played during focus sessions:

| Term | Definition |
| --- | --- |
| **Track** | A named ambient sound (Rain, Forest, Cafe, Brown Noise, Lo-Fi, or None). |
| **Built-in Track** | A bundled `.m4a` audio file shipped with the app. |
| **Generated Track** | A sound generated algorithmically at runtime when no bundled file is available. |

## Display Target

The screen where the notch window should appear:

| Term                | Definition                                                   |
| ------------------- | ------------------------------------------------------------ |
| **Main Display**    | The primary monitor (as identified by the system).           |
| **Notched Display** | The monitor with a physical notch (may be the same as main). |

## Notch Window

A borderless, non-activating panel positioned at the top-center of a display. Two visual appearances:

| Term | Definition |
| --- | --- |
| **Inside Notch** | The window fills the physical notch area of a notched display. Uses wider dimensions. |
| **Below Notch** | The window sits just below the notch area on a notched display. Uses standard dimensions. |

## Window State

The expansion state of the notch UI:

| Term | Definition |
| --- | --- |
| **Collapsed** | Compact state showing minimal controls (start button or session info). |
| **Expanded** | Full state showing timer, controls (audio, progress, settings), and session details. |

Expansion is triggered by a toggle click. Auto-collapse occurs after an idle timeout.

## Always On Top

A window-level behavior that keeps the notch panel above all other application windows. Configurable on/off. Default: **on**.

## Session Engine

The pure finite-state machine that owns Focus Session lifecycle, Round tracking, Long Break decisions, and audio-resume memory. It accepts **Session Events** and emits **Session Intents** describing the side effects the shell should perform. The Session Engine has no Foundation side effects of its own — no timers, no audio, no notifications, no persistence. See [ADR-0004](doc/adr/0004-session-engine-as-functional-core.md).

## Session Event

An input to the Session Engine: `start`, `pause`, `resume`, `tick`, `startNext`, `reset`. Every event carries `now: Date` so the engine is fully driven by an explicit clock.

## Session Intent

A side-effect command emitted by the Session Engine for the shell to execute: record a completion, stop/pause/resume audio, start the remembered audio track, notify the user, play the completion sound, flash the completion state, schedule the auto-start countdown.

## Session Config

The subset of preferences the Session Engine reads — Focus / Break / Long-Break durations, Rounds Before Long Break, completion-sound flags, and the auto-start flag. Snapshotted from `PresetSettingsStore` by the shell and pushed into the engine via `updateConfig(_:)`.
