import Foundation

internal enum SessionState: Equatable {
    case idle
    case running(remainingSeconds: Int, isWorkSession: Bool)
    case paused(remainingSeconds: Int, isWorkSession: Bool)
    case completed(isWorkSession: Bool)
}

// MARK: - SessionStateMachine

/// Value type that encapsulates session state query and transition logic,
/// eliminating duplicated pattern matching across FocusSessionViewModel.
@MainActor
internal enum SessionStateMachine {
    // MARK: - Queries

    static func isIdle(_ state: SessionState) -> Bool {
        if case .idle = state {
            return true
        }
        return false
    }

    static func isRunning(_ state: SessionState) -> Bool {
        if case .running = state {
            return true
        }
        return false
    }

    static func isPaused(_ state: SessionState) -> Bool {
        if case .paused = state {
            return true
        }
        return false
    }

    static func isCompleted(_ state: SessionState) -> Bool {
        if case .completed = state {
            return true
        }
        return false
    }

    static func remainingSeconds(in state: SessionState) -> Int? {
        switch state {
        case let .running(remaining, _), let .paused(remaining, _):
            remaining
        case .idle, .completed:
            nil
        }
    }

    static func isWorkSession(in state: SessionState) -> Bool? {
        switch state {
        case let .running(_, isWork), let .paused(_, isWork), let .completed(isWork):
            isWork
        case .idle:
            nil
        }
    }

    // MARK: - Transitions

    static func start(duration: Int, isWorkSession: Bool) -> SessionState {
        .running(remainingSeconds: duration, isWorkSession: isWorkSession)
    }

    static func tick(remainingSeconds: Int, from state: SessionState) -> SessionState? {
        guard case let .running(_, isWork) = state else { return nil }
        return .running(remainingSeconds: remainingSeconds, isWorkSession: isWork)
    }

    static func pause(from state: SessionState) -> SessionState? {
        guard case let .running(remaining, isWork) = state else { return nil }
        return .paused(remainingSeconds: remaining, isWorkSession: isWork)
    }

    static func resume(from state: SessionState) -> SessionState? {
        guard case let .paused(remaining, isWork) = state else { return nil }
        return .running(remainingSeconds: remaining, isWorkSession: isWork)
    }

    static func complete(from state: SessionState) -> SessionState? {
        guard case let .running(_, isWork) = state else { return nil }
        return .completed(isWorkSession: isWork)
    }

    static func reset() -> SessionState {
        .idle
    }
}

internal enum Preset: CaseIterable {
    case short
    case long

    var workDuration: Int {
        defaultWorkMinutes * 60
    }

    var breakDuration: Int {
        defaultBreakMinutes * 60
    }

    var longBreakDuration: Int {
        defaultLongBreakMinutes * 60
    }

    var defaultWorkMinutes: Int {
        switch self {
        case .short: 25
        case .long: 50
        }
    }

    var defaultBreakMinutes: Int {
        switch self {
        case .short: 5
        case .long: 10
        }
    }

    var defaultLongBreakMinutes: Int {
        switch self {
        case .short: 15
        case .long: 20
        }
    }

    var displayName: String {
        switch self {
        case .short: "25/5"
        case .long: "50/10"
        }
    }
}

internal enum DisplayTarget: String, CaseIterable, Identifiable {
    case mainDisplay
    case notchedDisplay

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .mainDisplay: "Main display"
        case .notchedDisplay: "Notched display"
        }
    }
}
