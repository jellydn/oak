import Foundation

internal struct FocusSessionRecord: Codable, Equatable, Identifiable {
    internal let id: UUID
    internal let intervalID: UUID?
    internal let startedAt: Date
    internal let endedAt: Date
    internal let durationMinutes: Int

    internal init(
        id: UUID = UUID(),
        intervalID: UUID? = nil,
        startedAt: Date,
        endedAt: Date,
        durationMinutes: Int
    ) {
        self.id = id
        self.intervalID = intervalID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationMinutes = durationMinutes
    }
}

internal struct FocusProgressSummary: Equatable {
    internal let focusMinutes: Int
    internal let completedSessions: Int
    internal let streakDays: Int
}
