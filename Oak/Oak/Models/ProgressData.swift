import Foundation

internal enum SessionType: String, Codable {
    case work
    case shortBreak
    case longBreak
}

internal struct SessionRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let type: SessionType
    let startTime: Date
    let endTime: Date
    let durationMinutes: Int

    init(id: UUID = UUID(), type: SessionType, startTime: Date, endTime: Date, durationMinutes: Int) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
    }
}

internal struct ProgressData: Codable, Identifiable {
    public let id: UUID
    let date: Date
    var focusMinutes: Int
    var completedSessions: Int
    var sessions: [SessionRecord]

    init(date: Date = Date(), focusMinutes: Int = 0, completedSessions: Int = 0, sessions: [SessionRecord] = []) {
        id = UUID()
        self.date = date
        self.focusMinutes = focusMinutes
        self.completedSessions = completedSessions
        self.sessions = sessions
    }

    enum CodingKeys: String, CodingKey {
        case id, date, focusMinutes, completedSessions, sessions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decode(Date.self, forKey: .date)
        focusMinutes = try container.decode(Int.self, forKey: .focusMinutes)
        completedSessions = try container.decode(Int.self, forKey: .completedSessions)
        sessions = try container.decodeIfPresent([SessionRecord].self, forKey: .sessions) ?? []
    }
}

internal struct DailyStats {
    let todayFocusMinutes: Int
    let todayCompletedSessions: Int
    let streakDays: Int
    let todaySessions: [SessionRecord]
}
