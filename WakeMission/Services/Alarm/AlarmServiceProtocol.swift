import Foundation

@MainActor
protocol AlarmServiceProtocol: AnyObject {
    func requestAuthorization() async -> Bool
    /// Schedules a user alarm, replacing any previous schedule with the same id.
    func schedule(_ entry: AlarmEntry) async throws
    func cancel(id: UUID) async throws
    /// Replaces the pending follow-up alarm with one that rings `delay` seconds from now.
    func armNext(after delay: TimeInterval) async
    /// Cancels the pending follow-up alarm of the current session (never the user's own alarms).
    func cancelAll() async
}
