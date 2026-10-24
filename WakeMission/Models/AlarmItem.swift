import Foundation
import SwiftData

@Model
final class AlarmItem: Identifiable {
    @Attribute(.unique) var id: UUID
    var time: Date
    var label: String
    var repeatDays: [Int] // 1: Sunday, 2: Monday, ..., 7: Saturday; empty = one-shot
    var isEnabled: Bool
    var soundName: String
    @Relationship(deleteRule: .cascade, inverse: \MissionItem.alarm)
    var missions: [MissionItem] = []
    var createdAt: Date

    init(
        id: UUID = UUID(),
        time: Date,
        label: String = "Wake Up",
        repeatDays: [Int] = [],
        isEnabled: Bool = true,
        soundName: String = AlarmTone.classic.rawValue,
        missions: [MissionItem] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.time = time
        self.label = label
        self.repeatDays = repeatDays
        self.isEnabled = isEnabled
        self.soundName = soundName
        self.missions = missions
        self.createdAt = createdAt
    }

    var sortedMissions: [MissionItem] {
        missions.sorted { $0.order < $1.order }
    }

    var formattedTime: String {
        time.formatted(date: .omitted, time: .shortened)
    }

    var nextFireDate: Date? {
        AlarmScheduleMath.nextFireDate(time: time, repeatDays: repeatDays)
    }

    var timeRemainingText: String {
        guard let next = nextFireDate else { return "" }
        return AlarmScheduleMath.countdownText(to: next)
    }

    var repeatSummary: String {
        if repeatDays.isEmpty { return "Once" }
        let set = Set(repeatDays)
        if set.count == 7 { return "Every day" }
        if set == [2, 3, 4, 5, 6] { return "Weekdays" }
        if set == [1, 7] { return "Weekends" }

        let symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return set.sorted().compactMap { day in
            (1...7).contains(day) ? symbols[day - 1] : nil
        }.joined(separator: " ")
    }
}
