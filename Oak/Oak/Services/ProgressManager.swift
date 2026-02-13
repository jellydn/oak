import Foundation

@MainActor
internal class ProgressManager: ObservableObject {
    @Published var dailyStats = DailyStats(todayFocusMinutes: 0, todayCompletedSessions: 0, streakDays: 0)

    private let userDefaults = UserDefaults.standard
    private let progressKey = "progressHistory"

    init() {
        loadProgress()
    }

    func recordSessionCompletion(durationMinutes: Int) {
        var records = loadRecords()
        let today = Calendar.current.startOfDay(for: Date())

        if let index = records.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            records[index].focusMinutes += durationMinutes
            records[index].completedSessions += 1
        } else {
            let newRecord = ProgressData(date: today, focusMinutes: durationMinutes, completedSessions: 1)
            records.append(newRecord)
        }

        records.sort { $0.date > $1.date }
        saveRecords(records)
        loadProgress()
    }

    private func loadRecords() -> [ProgressData] {
        guard let data = userDefaults.data(forKey: progressKey),
              let records = try? JSONDecoder().decode([ProgressData].self, from: data)
        else {
            return []
        }
        return records
    }

    private func saveRecords(_ records: [ProgressData]) {
        if let data = try? JSONEncoder().encode(records) {
            userDefaults.set(data, forKey: progressKey)
        }
    }

    private func loadProgress() {
        let records = loadRecords()
        let today = Calendar.current.startOfDay(for: Date())

        let todayRecord = records.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
        let todayFocusMinutes = todayRecord?.focusMinutes ?? 0
        let todayCompletedSessions = todayRecord?.completedSessions ?? 0
        let streakDays = calculateStreak(records: records)

        dailyStats = DailyStats(
            todayFocusMinutes: todayFocusMinutes,
            todayCompletedSessions: todayCompletedSessions,
            streakDays: streakDays
        )
    }

    private func calculateStreak(records: [ProgressData]) -> Int {
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())
        let calendar = Calendar.current

        for record in records {
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
