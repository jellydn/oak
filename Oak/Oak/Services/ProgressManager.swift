import Foundation

@MainActor
internal class ProgressManager: ObservableObject {
    @Published var dailyStats = DailyStats(
        todayFocusMinutes: 0,
        todayCompletedSessions: 0,
        streakDays: 0,
        todaySessions: []
    )

    private let userDefaults: UserDefaults
    private let progressKey = "progressHistory"
    private let retentionDays = 90
    private var lastLoadedDate: Date = Calendar.current.startOfDay(for: Date())
    private var dayCheckTimer: Timer?

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
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
        let today = Calendar.current.startOfDay(for: Date())
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
        startTime: Date = Date(),
        endTime: Date = Date()
    ) {
        let didChangeDay = checkDayChange()
        var records = loadRecords()
        let today = Calendar.current.startOfDay(for: Date())
        let newSession = SessionRecord(
            type: type,
            startTime: startTime,
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

        if !didChangeDay {
            loadProgress()
        }
    }

    private func loadRecords() -> [ProgressData] {
        guard let data = userDefaults.data(forKey: progressKey),
              let records = try? JSONDecoder().decode([ProgressData].self, from: data)
        else {
            return []
        }
        return records
    }

    private func pruneOldRecords(_ records: [ProgressData]) -> [ProgressData] {
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) else {
            return records
        }
        return records.filter { $0.date >= cutoffDate }
    }

    private func saveRecords(_ records: [ProgressData]) {
        if let data = try? JSONEncoder().encode(records) {
            userDefaults.set(data, forKey: progressKey)
        }
    }

    private func loadProgress() {
        let records = loadRecords()
        let today = Calendar.current.startOfDay(for: Date())
        lastLoadedDate = today

        let todayRecord = records.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
        let todayFocusMinutes = todayRecord?.focusMinutes ?? 0
        let todayCompletedSessions = todayRecord?.completedSessions ?? 0
        let streakDays = calculateStreak(records: records)
        let todaySessions = todayRecord?.sessions ?? []

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
        var currentDate = Calendar.current.startOfDay(for: Date())
        let calendar = Calendar.current

        for record in sortedRecords {
            let recordDate = calendar.startOfDay(for: record.date)
            let daysDifference = calendar.dateComponents([.day], from: recordDate, to: currentDate).day

            if daysDifference == 0 {
                if record.completedSessions > 0 {
                    streak = 1
                } else {
                    break
                }
            } else if daysDifference == 1 {
                if record.completedSessions > 0 {
                    streak += 1
                    currentDate = recordDate
                } else {
                    break
                }
            } else {
                break
            }
        }

        return streak
    }
}
