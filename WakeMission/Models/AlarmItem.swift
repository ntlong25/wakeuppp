import Foundation
import SwiftData

@Model
final class AlarmItem {
    @Attribute(.unique) var id: UUID
    var time: Date
    var label: String
    var repeatDays: [Int] // 1: Sunday, 2: Monday, ..., 7: Saturday
    var isEnabled: Bool
    var soundName: String
    var snoozeEnabled: Bool
    @Relationship(deleteRule: .cascade, inverse: \MissionItem.alarm)
    var missions: [MissionItem] = []
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        time: Date,
        label: String = "Wake Up",
        repeatDays: [Int] = [],
        isEnabled: Bool = true,
        soundName: String = "Radar",
        snoozeEnabled: Bool = false,
        missions: [MissionItem] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.time = time
        self.label = label
        self.repeatDays = repeatDays
        self.isEnabled = isEnabled
        self.soundName = soundName
        self.snoozeEnabled = snoozeEnabled
        self.missions = missions
        self.createdAt = createdAt
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
    
    var timeRemainingText: String {
        let calendar = Calendar.current
        let now = Date()
        
        var targetComponents = calendar.dateComponents([.hour, .minute], from: time)
        var todayTarget = calendar.date(bySettingHour: targetComponents.hour ?? 0, minute: targetComponents.minute ?? 0, second: 0, of: now) ?? now
        
        if todayTarget <= now {
            todayTarget = calendar.date(byAdding: .day, value: 1, to: todayTarget) ?? todayTarget
        }
        
        let diff = calendar.dateComponents([.hour, .minute], from: now, to: todayTarget)
        let hours = diff.hour ?? 0
        let minutes = diff.minute ?? 0
        
        if hours > 0 {
            return "in \(hours)h \(minutes)m"
        } else {
            return "in \(minutes)m"
        }
    }
    
    var repeatSummary: String {
        if repeatDays.isEmpty {
            return "Once"
        }
        if repeatDays.count == 7 {
            return "Every day"
        }
        if Set(repeatDays) == Set([2, 3, 4, 5, 6]) {
            return "Weekdays"
        }
        if Set(repeatDays) == Set([1, 7]) {
            return "Weekends"
        }
        
        let symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return repeatDays.sorted().compactMap { day in
            guard day >= 1 && day <= 7 else { return nil }
            return symbols[day - 1]
        }.joined(separator: " ")
    }
}
