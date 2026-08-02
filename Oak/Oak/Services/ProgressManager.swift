import Foundation

@MainActor
internal class ProgressManager: ObservableObject {
    @Published var dailyStats = DailyStats(
        todayFocusMinutes: 0,
        todayCompletedSessions: 0,
        streakDays: 0,
        todaySessions: []
    )

    private let currentDate: () -> Date
    private let progressStore: any ProgressStoring
    private let retentionDays = 90
    private var lastLoadedDate: Date
    private var dayCheckTimer: Timer?

    init(
        userDefaults: UserDefaults = .standard,
        progressStore: (any ProgressStoring)? = nil,
        currentDate: @escaping () -> Date = Date.init
    ) {
        self.currentDate = currentDate
        self.progressStore = progressStore ?? UserDefaultsProgressStore(userDefaults: userDefaults)
        lastLoadedDate = Calendar.current.startOfDay(for: currentDate())
        loadProgress()
        startDayCheckTimer()
    }

    deinit {
        dayCheckTimer?.invalidate()
    }

    private func startDayCheckTimer() {
        dayCheckTimer?.invalidate()
        dayCheckTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkDayChange()
            }
        }
    }

    @discardableResult
    func checkDayChange() -> Bool {
        let today = Calendar.current.startOfDay(for: currentDate())
        if !Calendar.current.isDate(lastLoadedDate, inSameDayAs: today) {
            lastLoadedDate = today
            loadProgress()
            return true
        }
        return false
    }

    func recordSessionCompletion(
        durationMinutes: Int,
        type: SessionType = .work,
        startTime: Date? = nil,
        endTime: Date = Date()
    ) {
        let resolvedStartTime = startTime ?? endTime.addingTimeInterval(TimeInterval(-durationMinutes * 60))
        guard durationMinutes > 0, resolvedStartTime <= endTime else { return }

        checkDayChange()
        var records = loadRecords()
        let today = Calendar.current.startOfDay(for: currentDate())
        let newSession = SessionRecord(
            type: type,
            startTime: resolvedStartTime,
            endTime: endTime,
            durationMinutes: durationMinutes
        )

        if let index = records.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            if type == .work {
                records[index].focusMinutes += durationMinutes
                records[index].completedSessions += 1
            }
            records[index].sessions.append(newSession)
        } else {
            let newRecord = ProgressData(
                date: today,
                focusMinutes: type == .work ? durationMinutes : 0,
                completedSessions: type == .work ? 1 : 0,
                sessions: [newSession]
            )
            records.append(newRecord)
        }

        records.sort { $0.date > $1.date }
        saveRecords(pruneOldRecords(records))

        loadProgress()
    }

    private func loadRecords() -> [ProgressData] {
        progressStore.load()
    }

    private func pruneOldRecords(_ records: [ProgressData]) -> [ProgressData] {
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: currentDate()) else {
            return records
        }
        return records.filter { $0.date >= cutoffDate }
    }

    private func saveRecords(_ records: [ProgressData]) {
        progressStore.save(records)
    }

    private func loadProgress() {
        let records = loadRecords()
        let today = Calendar.current.startOfDay(for: currentDate())
        lastLoadedDate = today

        let todayRecord = records.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
        let todayFocusMinutes = todayRecord?.focusMinutes ?? 0
        let todayCompletedSessions = todayRecord?.completedSessions ?? 0
        let streakDays = calculateStreak(records: records)
        let todaySessions = (todayRecord?.sessions ?? []).sorted { $0.startTime > $1.startTime }

        dailyStats = DailyStats(
            todayFocusMinutes: todayFocusMinutes,
            todayCompletedSessions: todayCompletedSessions,
            streakDays: streakDays,
            todaySessions: todaySessions
        )
    }

    private func calculateStreak(records: [ProgressData]) -> Int {
        let sortedRecords = records.sorted { $0.date > $1.date }
        var streak = 0
        var currentDay = Calendar.current.startOfDay(for: currentDate())
        let calendar = Calendar.current

        for record in sortedRecords {
            let recordDate = calendar.startOfDay(for: record.date)
            let daysDifference = calendar.dateComponents([.day], from: recordDate, to: currentDay).day

            if daysDifference == 0 {
                if record.completedSessions > 0 {
                    streak = 1
                } else {
                    continue
                }
            } else if daysDifference == 1 {
                if record.completedSessions > 0 {
                    streak += 1
                    currentDay = recordDate
                } else {
                    break
                }
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Export / Import

    var allRecords: [ProgressData] {
        loadRecords()
    }

    func exportJSON() -> Data? {
        let records = allRecords
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(records)
    }

    func exportCSV() -> String {
        let records = allRecords
        var csv = "Date,Type,Start,End,Duration (min)\n"
        let formatter = ISO8601DateFormatter()
        for record in records {
            for session in record.sessions.sorted(by: { $0.startTime > $1.startTime }) {
                csv += "\(formatter.string(from: record.date)),"
                    + "\(session.type.rawValue),"
                    + "\(formatter.string(from: session.startTime)),"
                    + "\(formatter.string(from: session.endTime)),"
                    + "\(session.durationMinutes)\n"
            }
        }
        return csv
    }

    func importRecords(from data: Data) -> Int {
        guard let imported = try? JSONDecoder().decode([ProgressData].self, from: data),
              !imported.isEmpty
        else {
            return 0
        }
        var existing = allRecords
        for record in imported {
            if let index = existing.firstIndex(where: { $0.date == record.date }) {
                var merged = existing[index]
                merged.focusMinutes += record.focusMinutes
                merged.completedSessions += record.completedSessions
                merged.sessions.append(contentsOf: record.sessions)
                existing[index] = merged
            } else {
                existing.append(record)
            }
        }
        existing.sort { $0.date > $1.date }
        saveRecords(existing)
        loadProgress()
        return imported.count
    }
}
