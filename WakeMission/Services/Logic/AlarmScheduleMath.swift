import Foundation

/// Pure date math for alarms. No AlarmKit dependency so it is unit-testable.
enum AlarmScheduleMath {
    /// Next wall-clock occurrence (seconds = 0) of `time`'s hour/minute strictly after `now`.
    /// `repeatDays` uses 1 = Sunday … 7 = Saturday; empty means one-shot (next occurrence today/tomorrow).
    static func nextFireDate(
        time: Date,
        repeatDays: [Int],
        after now: Date = Date(),
        calendar: Calendar = .current
    ) -> Date? {
        let hm = calendar.dateComponents([.hour, .minute], from: time)
        let days = Set(repeatDays.filter { (1...7).contains($0) })

        if days.isEmpty {
            var dc = DateComponents()
            dc.hour = hm.hour
            dc.minute = hm.minute
            dc.second = 0
            return calendar.nextDate(after: now, matching: dc, matchingPolicy: .nextTime)
        }

        return days.compactMap { day -> Date? in
            var dc = DateComponents()
            dc.weekday = day
            dc.hour = hm.hour
            dc.minute = hm.minute
            dc.second = 0
            return calendar.nextDate(after: now, matching: dc, matchingPolicy: .nextTime)
        }.min()
    }

    /// "in 7h 42m", "in 12m", "in 1d 2h"
    static func countdownText(to target: Date, from now: Date = Date()) -> String {
        let total = max(0, Int(target.timeIntervalSince(now) / 60))
        let days = total / (60 * 24)
        let hours = (total / 60) % 24
        let minutes = total % 60
        if days > 0 { return "in \(days)d \(hours)h" }
        if hours > 0 { return "in \(hours)h \(minutes)m" }
        return "in \(max(minutes, 1))m"
    }
}
