import Foundation
import SwiftData

@Model
final class AlarmSessionRecord: Identifiable {
    @Attribute(.unique) var id: UUID
    var alarmId: UUID
    var scheduledAt: Date
    var triggeredAt: Date
    var completedAt: Date?
    var missionsCompleted: Int
    var durationSeconds: Double
    var success: Bool

    init(
        id: UUID = UUID(),
        alarmId: UUID,
        scheduledAt: Date,
        triggeredAt: Date = Date(),
        completedAt: Date? = nil,
        missionsCompleted: Int = 0,
        durationSeconds: Double = 0,
        success: Bool = false
    ) {
        self.id = id
        self.alarmId = alarmId
        self.scheduledAt = scheduledAt
        self.triggeredAt = triggeredAt
        self.completedAt = completedAt
        self.missionsCompleted = missionsCompleted
        self.durationSeconds = durationSeconds
        self.success = success
    }
}
