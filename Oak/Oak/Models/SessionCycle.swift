import Foundation

internal struct SessionCycle {
    internal struct Configuration {
        let workDuration: Int
        let breakDuration: Int
        let longBreakDuration: Int
        let roundsBeforeLongBreak: Int
    }

    internal struct Interval {
        let duration: Int
        let isWorkSession: Bool
        let isLongBreak: Bool
    }

    private(set) var completedRounds: Int = 0
    private(set) var isWorkSession: Bool = true
    private(set) var isLongBreak: Bool = false

    private var roundTrackingDate: Date
    private let calendar: Calendar

    internal init(currentDate: Date, calendar: Calendar = .current) {
        self.calendar = calendar
        roundTrackingDate = calendar.startOfDay(for: currentDate)
    }

    internal mutating func startWork(currentDate: Date) {
        resetRoundsIfNeeded(currentDate: currentDate)
        completedRounds = 0
        isWorkSession = true
        isLongBreak = false
    }

    internal mutating func startNext(
        after completedWorkSession: Bool,
        currentDate: Date,
        configuration: Configuration
    ) -> Interval {
        resetRoundsIfNeeded(currentDate: currentDate)
        isWorkSession = !completedWorkSession

        if isWorkSession {
            isLongBreak = false
            return Interval(duration: configuration.workDuration, isWorkSession: true, isLongBreak: false)
        }

        isLongBreak = completedRounds >= configuration.roundsBeforeLongBreak
        let duration = isLongBreak ? configuration.longBreakDuration : configuration.breakDuration
        return Interval(duration: duration, isWorkSession: false, isLongBreak: isLongBreak)
    }

    internal func nextBreakIsLong(roundsBeforeLongBreak: Int) -> Bool {
        completedRounds >= roundsBeforeLongBreak
    }

    internal mutating func complete(currentDate: Date) -> SessionType {
        resetRoundsIfNeeded(currentDate: currentDate)

        if isWorkSession {
            completedRounds += 1
            return .work
        }

        if isLongBreak {
            completedRounds = 0
            return .longBreak
        }

        return .shortBreak
    }

    internal mutating func reset() {
        completedRounds = 0
        isWorkSession = true
        isLongBreak = false
    }

    private mutating func resetRoundsIfNeeded(currentDate: Date) {
        let today = calendar.startOfDay(for: currentDate)
        if !calendar.isDate(roundTrackingDate, inSameDayAs: today) {
            roundTrackingDate = today
            completedRounds = 0
        }
    }
}
