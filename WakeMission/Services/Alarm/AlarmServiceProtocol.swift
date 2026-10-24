import Foundation

@MainActor
protocol AlarmServiceProtocol: AnyObject {
    func requestAuthorization() async -> Bool
    /// Replaces any pending WakeMission alarm with one that rings `delay` seconds from now.
    func armNext(after delay: TimeInterval) async
    /// Cancels every pending WakeMission alarm of the current session.
    func cancelAll() async
}
