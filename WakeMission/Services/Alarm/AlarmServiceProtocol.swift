import Foundation

@MainActor
protocol AlarmServiceProtocol: AnyObject {
    func requestAuthorization() async -> Bool
    /// Schedules (replacing any existing schedule for the same id). No-op if the alarm is disabled.
    func schedule(alarm: AlarmItem) async throws
    func cancel(id: UUID) async throws
    func update(alarm: AlarmItem) async throws
    /// Backup alarms that re-fire until missions are completed.
    func scheduleNags(parentId: UUID) async
    func cancelNags() async
}
