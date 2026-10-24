import Foundation

enum StreakCalculator {
    /// Consecutive calendar days with at least one success, counting back from today.
    /// If today has no success yet, counting starts from yesterday so the streak survives until the user wakes up.
    static func currentStreak(successDates: [Date], today: Date = Date(), calendar: Calendar = .current) -> Int {
        let days = Set(successDates.map { calendar.startOfDay(for: $0) })
        var cursor = calendar.startOfDay(for: today)
        if !days.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }
        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    /// Success counts for the last `days` days, oldest first, ending today.
    static func dailyCounts(successDates: [Date], days: Int = 7, today: Date = Date(), calendar: Calendar = .current) -> [(day: Date, count: Int)] {
        let start = calendar.startOfDay(for: today)
        return (0..<days).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: start) else { return nil }
            let count = successDates.filter { calendar.isDate($0, inSameDayAs: day) }.count
            return (day, count)
        }
    }

    /// Mean time of day (seconds since midnight) of the given dates, nil if empty.
    static func averageTimeOfDay(_ dates: [Date], calendar: Calendar = .current) -> TimeInterval? {
        guard !dates.isEmpty else { return nil }
        let total = dates.reduce(0.0) { acc, date in
            let c = calendar.dateComponents([.hour, .minute, .second], from: date)
            return acc + Double((c.hour ?? 0) * 3600 + (c.minute ?? 0) * 60 + (c.second ?? 0))
        }
        return total / Double(dates.count)
    }
}
