import Foundation

struct ProgressData: Codable, Identifiable {
    let id: UUID
    let date: Date
    var focusMinutes: Int
    var completedSessions: Int
    
    init(date: Date = Date(), focusMinutes: Int = 0, completedSessions: Int = 0) {
        self.id = UUID()
        self.date = date
        self.focusMinutes = focusMinutes
        self.completedSessions = completedSessions
    }
}

struct DailyStats {
    let todayFocusMinutes: Int
    let todayCompletedSessions: Int
    let streakDays: Int
}
