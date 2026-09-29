import Foundation

internal protocol FocusProgressStoring {
    func load() -> [FocusSessionRecord]
    func save(_ records: [FocusSessionRecord])
}

internal final class UserDefaultsFocusProgressStore: FocusProgressStoring {
    private let userDefaults: UserDefaults
    private let key: String

    internal init(userDefaults: UserDefaults = .standard, key: String = "iosFocusSessionHistory") {
        self.userDefaults = userDefaults
        self.key = key
    }

    internal func load() -> [FocusSessionRecord] {
        guard let data = userDefaults.data(forKey: key),
              let records = try? JSONDecoder().decode([FocusSessionRecord].self, from: data)
        else {
            return []
        }
        return records
    }

    internal func save(_ records: [FocusSessionRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        userDefaults.set(data, forKey: key)
    }
}

internal struct FocusProgressRepository {
    private let store: any FocusProgressStoring
    private let calendar: Calendar

    internal init(store: any FocusProgressStoring, calendar: Calendar = .current) {
        self.store = store
        self.calendar = calendar
    }

    internal func record(_ completion: CompletedFocusInterval) {
        guard completion.kind.isFocus else { return }
        let minutes = completion.durationSeconds / 60
        guard minutes > 0 else { return }

        var records = store.load()
        guard !records.contains(where: { $0.intervalID == completion.id }) else { return }
        records.append(
            FocusSessionRecord(
                intervalID: completion.id,
                startedAt: completion.startedAt,
                endedAt: completion.endedAt,
                durationMinutes: minutes
            )
        )
        store.save(records.sorted { $0.endedAt > $1.endedAt })
    }

    internal func summary(on date: Date) -> FocusProgressSummary {
        let records = store.load()
        let todayRecords = records.filter { calendar.isDate($0.endedAt, inSameDayAs: date) }
        return FocusProgressSummary(
            focusMinutes: todayRecords.reduce(0) { $0 + $1.durationMinutes },
            completedSessions: todayRecords.count,
            streakDays: streak(records: records, through: date)
        )
    }

    private func streak(records: [FocusSessionRecord], through date: Date) -> Int {
        let completedDays = Set(records.map { calendar.startOfDay(for: $0.endedAt) })
        var day = calendar.startOfDay(for: date)
        if !completedDays.contains(day), let yesterday = calendar.date(byAdding: .day, value: -1, to: day) {
            day = yesterday
        }

        var count = 0
        while completedDays.contains(day) {
            count += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previousDay
        }
        return count
    }
}
