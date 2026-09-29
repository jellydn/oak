import Foundation

internal struct FocusSessionEngine: Codable {
    private static let roundsBeforeLongBreak = 4

    private(set) var selectedPreset: FocusPreset = .short
    private(set) var phase: FocusSessionPhase = .idle
    private(set) var intervalKind: FocusIntervalKind = .focus
    private(set) var intervalDuration: Int = FocusPreset.short.workDuration
    private(set) var completedFocusRounds: Int = 0
    private(set) var endDate: Date?

    private var remainingInterval = TimeInterval(FocusPreset.short.workDuration)
    private var startedAt: Date?
    private var intervalID: UUID?

    internal var remainingSeconds: Int {
        max(0, Int(ceil(remainingInterval)))
    }

    internal var currentIntervalID: UUID? {
        intervalID
    }

    internal var progress: Double {
        guard phase != .idle, intervalDuration > 0 else { return 0 }
        return min(1, max(0, (Double(intervalDuration) - remainingInterval) / Double(intervalDuration)))
    }

    internal var displayTime: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    internal mutating func selectPreset(_ preset: FocusPreset) {
        guard phase == .idle else { return }
        selectedPreset = preset
        remainingInterval = TimeInterval(preset.workDuration)
        intervalDuration = preset.workDuration
    }

    internal mutating func start(now: Date) {
        guard phase == .idle else { return }
        completedFocusRounds = 0
        startInterval(.focus, duration: selectedPreset.workDuration, now: now)
    }

    @discardableResult
    internal mutating func pause(now: Date) -> CompletedFocusInterval? {
        guard phase == .running else { return nil }
        if let completion = refresh(now: now) {
            return completion
        }
        endDate = nil
        phase = .paused
        return nil
    }

    internal mutating func resume(now: Date) {
        guard phase == .paused else { return }
        endDate = now.addingTimeInterval(remainingInterval)
        phase = .running
    }

    @discardableResult
    internal mutating func refresh(now: Date) -> CompletedFocusInterval? {
        guard phase == .running, let endDate else { return nil }
        remainingInterval = max(0, endDate.timeIntervalSince(now))
        guard remainingInterval == 0 else { return nil }

        let completion = CompletedFocusInterval(
            id: intervalID ?? UUID(),
            kind: intervalKind,
            startedAt: startedAt ?? endDate.addingTimeInterval(TimeInterval(-intervalDuration)),
            endedAt: endDate,
            durationSeconds: intervalDuration
        )
        if intervalKind.isFocus {
            completedFocusRounds += 1
        } else if intervalKind == .longBreak {
            completedFocusRounds = 0
        }
        self.endDate = nil
        phase = .completed
        return completion
    }

    internal mutating func startNext(now: Date) {
        guard phase == .completed else { return }

        if intervalKind.isFocus {
            let isLongBreak = completedFocusRounds >= Self.roundsBeforeLongBreak
            startInterval(
                isLongBreak ? .longBreak : .shortBreak,
                duration: isLongBreak ? selectedPreset.longBreakDuration : selectedPreset.breakDuration,
                now: now
            )
        } else {
            startInterval(.focus, duration: selectedPreset.workDuration, now: now)
        }
    }

    internal mutating func reset() {
        phase = .idle
        intervalKind = .focus
        remainingInterval = TimeInterval(selectedPreset.workDuration)
        intervalDuration = selectedPreset.workDuration
        completedFocusRounds = 0
        endDate = nil
        startedAt = nil
        intervalID = nil
    }

    private mutating func startInterval(_ kind: FocusIntervalKind, duration: Int, now: Date) {
        intervalKind = kind
        intervalDuration = duration
        remainingInterval = TimeInterval(duration)
        startedAt = now
        intervalID = UUID()
        endDate = now.addingTimeInterval(TimeInterval(duration))
        phase = .running
    }
}
