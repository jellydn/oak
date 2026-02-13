import Foundation

internal struct ProgressData: Codable, Identifiable {
    public let id: UUID
    let date: Date
    var focusMinutes: Int
    var completedSessions: Int

    init(date: Date = Date(), focusMinutes: Int = 0, completedSessions: Int = 0) {
        id = UUID()
        self.date = date
        self.focusMinutes = focusMinutes
        self.completedSessions = completedSessions
    }
}

internal struct DailyStats {
    let todayFocusMinutes: Int
    let todayCompletedSessions: Int
    let streakDays: Int
}
