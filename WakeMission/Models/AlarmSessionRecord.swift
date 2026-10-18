import Foundation
import SwiftData

@Model
final class AlarmSessionRecord {
    @Attribute(.unique) var id: UUID
    var alarmId: UUID
    var scheduledAt: Date
    var triggeredAt: Date
    var completedAt: Date?
    var missionsCompleted: Int
    var durationSeconds: Double
    var snoozeCount: Int
    var success: Bool
    
    init(
        id: UUID = UUID(),
        alarmId: UUID,
        scheduledAt: Date,
        triggeredAt: Date = Date(),
        completedAt: Date? = nil,
        missionsCompleted: Int = 0,
        durationSeconds: Double = 0,
        snoozeCount: Int = 0,
        success: Bool = false
    ) {
        self.id = id
        self.alarmId = alarmId
        self.scheduledAt = scheduledAt
        self.triggeredAt = triggeredAt
        self.completedAt = completedAt
        self.missionsCompleted = missionsCompleted
        self.durationSeconds = durationSeconds
        self.snoozeCount = snoozeCount
        self.success = success
    }
}
