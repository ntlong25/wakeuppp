import Foundation

/// One alarm created in the app. `id` is also its AlarmKit id.
struct AlarmEntry: Identifiable, Equatable, Codable, Sendable {
    var id = UUID()
    var hour: Int
    var minute: Int
    var label: String = ""
    /// 1 = Sunday … 7 = Saturday; empty = one-shot.
    var repeatDays: Set<Int> = []
    var isEnabled: Bool = true
    /// When a one-shot alarm is due. AlarmKit removes it after firing, so this tells us it is over.
    var oneShotFireDate: Date?

    func nextFireDate(after now: Date = Date(), calendar: Calendar = .current) -> Date? {
        AlarmScheduleMath.nextFireDate(hour: hour, minute: minute, repeatDays: repeatDays, after: now, calendar: calendar)
    }

    /// True once an enabled one-shot alarm's time has passed.
    func isExpired(now: Date = Date()) -> Bool {
        guard isEnabled, repeatDays.isEmpty, let oneShotFireDate else { return false }
        return oneShotFireDate <= now
    }

    /// Weekdays in the order the user's calendar shows them (1 = Sunday … 7 = Saturday).
    static func weekOrder(calendar: Calendar = .current) -> [Int] {
        (0..<7).map { (calendar.firstWeekday - 1 + $0) % 7 + 1 }
    }

    func repeatSummary(calendar: Calendar = .current) -> String {
        switch repeatDays {
        case []: return String(localized: "Never")
        case [1, 2, 3, 4, 5, 6, 7]: return String(localized: "Every day")
        case [2, 3, 4, 5, 6]: return String(localized: "Weekdays")
        case [1, 7]: return String(localized: "Weekends")
        default:
            let symbols = calendar.shortWeekdaySymbols
            return Self.weekOrder(calendar: calendar)
                .filter(repeatDays.contains)
                .map { symbols[$0 - 1] }
                .joined(separator: ", ")
        }
    }

    var displayLabel: String {
        label.isEmpty ? String(localized: "Alarm") : label
    }

    /// Second line of a row, as in the Clock app: "Alarm" or "Alarm, Weekdays".
    var rowSubtitle: String {
        repeatDays.isEmpty ? displayLabel : "\(displayLabel), \(repeatSummary())"
    }
}

/// Keeps the saved alarms and AlarmKit in step.
@MainActor
final class AlarmStore: ObservableObject {
    @Published private(set) var alarms: [AlarmEntry]
    @Published var scheduleFailed = false

    private static let key = "com.wakemission.alarms"
    private let alarmService: AlarmServiceProtocol

    init(alarmService: AlarmServiceProtocol = AlarmService.shared) {
        self.alarmService = alarmService
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode([AlarmEntry].self, from: data) {
            alarms = saved
        } else {
            alarms = []
        }
    }

    var sortedAlarms: [AlarmEntry] {
        alarms.sorted { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
    }

    /// Adds or updates an alarm and schedules it.
    func save(_ entry: AlarmEntry) async {
        var entry = entry
        entry.isEnabled = true
        await apply(entry)
    }

    func setEnabled(_ enabled: Bool, for entry: AlarmEntry) async {
        var entry = entry
        entry.isEnabled = enabled
        await apply(entry)
    }

    func delete(_ entry: AlarmEntry) async {
        alarms.removeAll { $0.id == entry.id }
        persist()
        try? await alarmService.cancel(id: entry.id)
    }

    /// One-shot alarms that have fired turn themselves off, like in the Clock app.
    func disableExpiredAlarms(now: Date = Date()) {
        var changed = false
        for index in alarms.indices where alarms[index].isExpired(now: now) {
            alarms[index].isEnabled = false
            alarms[index].oneShotFireDate = nil
            changed = true
        }
        if changed { persist() }
    }

    private func apply(_ entry: AlarmEntry) async {
        var entry = entry
        entry.oneShotFireDate = entry.isEnabled && entry.repeatDays.isEmpty ? entry.nextFireDate() : nil
        store(entry)

        do {
            if entry.isEnabled {
                try await alarmService.schedule(entry)
            } else {
                try? await alarmService.cancel(id: entry.id)
            }
        } catch {
            print("Failed to schedule alarm: \(error)")
            entry.isEnabled = false
            entry.oneShotFireDate = nil
            store(entry)
            scheduleFailed = true
        }
    }

    private func store(_ entry: AlarmEntry) {
        if let index = alarms.firstIndex(where: { $0.id == entry.id }) {
            alarms[index] = entry
        } else {
            alarms.append(entry)
        }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
