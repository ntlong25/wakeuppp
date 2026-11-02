import Foundation

/// Pure date math for alarms. No AlarmKit dependency so it is unit-testable.
enum AlarmScheduleMath {
    /// Next wall-clock occurrence (seconds = 0) of hour:minute strictly after `now`.
    /// `repeatDays` uses 1 = Sunday … 7 = Saturday; empty means one-shot (today or tomorrow).
    static func nextFireDate(
        hour: Int,
        minute: Int,
        repeatDays: Set<Int>,
        after now: Date = Date(),
        calendar: Calendar = .current
    ) -> Date? {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        components.second = 0

        let days = repeatDays.filter { (1...7).contains($0) }
        if days.isEmpty {
            return calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime)
        }
        return days.compactMap { day -> Date? in
            var dated = components
            dated.weekday = day
            return calendar.nextDate(after: now, matching: dated, matchingPolicy: .nextTime)
        }.min()
    }
}
