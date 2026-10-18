import Foundation

protocol AlarmServiceProtocol: Sendable {
    func requestAuthorization() async -> Bool
    func schedule(alarm: AlarmItem) async throws
    func cancel(id: UUID) async throws
    func update(alarm: AlarmItem) async throws
    func snooze(id: UUID) async throws
    func isAlarmScheduled(id: UUID) async -> Bool
}
