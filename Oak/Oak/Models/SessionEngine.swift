import Foundation

/// Pure finite-state machine that owns Focus Session lifecycle, Round
/// tracking, Long Break decisions, and audio-resume memory.
///
/// The engine performs no side effects of its own. Every `apply(_:)` returns
/// an ordered array of `SessionIntent` describing what the shell should do.
///
/// Time is pushed in per event (`now: Date`). The injected `Calendar`
/// determines day-rollover for round resets.
///
/// See [doc/adr/0004-session-engine-as-functional-core.md](../../../doc/adr/0004-session-engine-as-functional-core.md).
internal struct SessionEngine {
    // MARK: - Observable state

    private(set) var state: SessionState = .idle
    private(set) var completedRounds: Int = 0

    // MARK: - Internal state

    private var config: SessionConfig
    private let calendar: Calendar
    private var roundTrackingDate: Date

    private var sessionStartSeconds: Int = 0
    private var currentRemainingSeconds: Int = 0
    private var sessionStartTime: Date?
    private var sessionEndDate: Date?
    private var wasAutoStarted: Bool = false

    private var currentlyPlaying: AudioTrack = .none
    private var lastPlayingAudioTrack: AudioTrack = .none

    // MARK: - Init

    init(config: SessionConfig, calendar: Calendar = .current, now: Date) {
        self.config = config
        self.calendar = calendar
        roundTrackingDate = calendar.startOfDay(for: now)
    }

    // MARK: - Shell synchronisation (non-events)

    mutating func updateConfig(_ new: SessionConfig) {
        config = new
    }

    mutating func setCurrentlyPlayingAudio(_ track: AudioTrack) {
        currentlyPlaying = track
    }

    // MARK: - Derived

    /// If we are in `.completed`, what kind of session would `.startNext`
    /// begin right now, given current `completedRounds` and `config`?
    var nextSessionPreview: SessionType? {
        guard case let .completed(kind) = state else { return nil }
        switch kind {
        case .work:
            return shouldUseLongBreak ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            return .work
        }
    }

    // MARK: - Event dispatch

    @discardableResult
    mutating func apply(_ event: SessionEvent) -> [SessionIntent] {
        switch event {
        case let .start(now):
            handleStart(now: now)
        case let .pause(now):
            handlePause(now: now)
        case let .resume(now):
            handleResume(now: now)
        case let .tick(now):
            handleTick(now: now)
        case let .startNext(now, isAutoStart):
            handleStartNext(now: now, isAutoStart: isAutoStart)
        case .reset:
            handleReset()
        }
    }

    // MARK: - Event handlers

    private mutating func handleStart(now: Date) -> [SessionIntent] {
        guard case .idle = state else { return [] }
        resetCompletedRoundsIfNeeded(now: now)
        completedRounds = 0
        wasAutoStarted = false
        beginSession(kind: .work, durationSeconds: config.workSeconds, now: now)
        return []
    }

    private mutating func handlePause(now: Date) -> [SessionIntent] {
        guard case let .running(remaining, kind) = state else { return [] }
        currentRemainingSeconds = remaining
        sessionEndDate = nil
        state = .paused(remainingSeconds: remaining, kind: kind)
        _ = now
        return [.pauseAudio]
    }

    private mutating func handleResume(now: Date) -> [SessionIntent] {
        guard case let .paused(remaining, kind) = state else { return [] }
        currentRemainingSeconds = remaining
        sessionEndDate = now.addingTimeInterval(TimeInterval(remaining))
        state = .running(remainingSeconds: remaining, kind: kind)
        return [.resumePausedAudio]
    }

    private mutating func handleTick(now: Date) -> [SessionIntent] {
        guard case let .running(_, kind) = state,
              let endDate = sessionEndDate
        else {
            return []
        }
        let remaining = max(0, Int(ceil(endDate.timeIntervalSince(now))))
        currentRemainingSeconds = remaining

        if remaining <= 0 {
            return completeSession(kind: kind, now: now)
        } else {
            state = .running(remainingSeconds: remaining, kind: kind)
            return []
        }
    }

    private mutating func handleStartNext(now: Date, isAutoStart: Bool) -> [SessionIntent] {
        guard case let .completed(completedKind) = state else { return [] }
        resetCompletedRoundsIfNeeded(now: now)
        wasAutoStarted = isAutoStart

        let nextKind: SessionType
        let nextSeconds: Int
        switch completedKind {
        case .work:
            if shouldUseLongBreak {
                nextKind = .longBreak
                nextSeconds = config.longBreakSeconds
            } else {
                nextKind = .shortBreak
                nextSeconds = config.breakSeconds
            }
        case .shortBreak, .longBreak:
            nextKind = .work
            nextSeconds = config.workSeconds
        }

        beginSession(kind: nextKind, durationSeconds: nextSeconds, now: now)

        if nextKind == .work, lastPlayingAudioTrack != .none {
            return [.startRememberedAudio(track: lastPlayingAudioTrack)]
        }
        return []
    }

    private mutating func handleReset() -> [SessionIntent] {
        currentRemainingSeconds = 0
        sessionStartSeconds = 0
        sessionEndDate = nil
        sessionStartTime = nil
        completedRounds = 0
        wasAutoStarted = false
        lastPlayingAudioTrack = .none
        state = .idle
        return [.stopAudio]
    }

    // MARK: - Helpers

    private mutating func beginSession(kind: SessionType, durationSeconds: Int, now: Date) {
        currentRemainingSeconds = durationSeconds
        sessionStartSeconds = durationSeconds
        sessionStartTime = now
        sessionEndDate = now.addingTimeInterval(TimeInterval(durationSeconds))
        state = .running(remainingSeconds: durationSeconds, kind: kind)
    }

    private mutating func completeSession(kind: SessionType, now: Date) -> [SessionIntent] {
        resetCompletedRoundsIfNeeded(now: now)
        var intents: [SessionIntent] = []

        switch kind {
        case .work:
            completedRounds += 1
        case .longBreak:
            completedRounds = 0
        case .shortBreak:
            break
        }

        let durationMinutes = (sessionStartSeconds - currentRemainingSeconds) / 60
        if durationMinutes > 0, let startTime = sessionStartTime {
            let record = SessionRecord(
                type: kind,
                startTime: startTime,
                endTime: now,
                durationMinutes: durationMinutes
            )
            intents.append(.recordCompletion(record))
        }

        intents.append(.notifyCompleted(kind: kind))

        if currentlyPlaying != .none {
            lastPlayingAudioTrack = currentlyPlaying
        }
        intents.append(.stopAudio)

        let shouldPlaySound: Bool = if kind == .work {
            config.playSoundOnSessionCompletion
        } else {
            config.playSoundOnBreakCompletion && !wasAutoStarted
        }
        if shouldPlaySound {
            intents.append(.playCompletionSound)
        }

        intents.append(.flashCompletion)

        if config.autoStartNextInterval {
            intents.append(.scheduleAutoStartCountdown)
        }

        sessionEndDate = nil
        state = .completed(kind: kind)
        return intents
    }

    private var shouldUseLongBreak: Bool {
        completedRounds >= config.roundsBeforeLongBreak
    }

    private mutating func resetCompletedRoundsIfNeeded(now: Date) {
        let today = calendar.startOfDay(for: now)
        guard !calendar.isDate(roundTrackingDate, inSameDayAs: today) else {
            return
        }
        roundTrackingDate = today
        completedRounds = 0
    }
}
