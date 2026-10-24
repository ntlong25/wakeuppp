import Foundation

/// The wake-up flow currently in progress (a Clock alarm was stopped, missions not finished yet).
/// Persisted in UserDefaults so App Intents can hand off to a cold-launched app.
struct RingingSession: Codable, Equatable, Sendable {
    var startedAt: Date
    /// AlarmKit alarm ids armed by us that must be cancelled on completion.
    var pendingAlarmIds: [UUID]
}

enum RingingStore {
    private static let key = "com.wakemission.ringingSession"
    /// Sessions older than this are abandoned and never re-armed.
    static let maxAge: TimeInterval = 60 * 60

    static func current(now: Date = Date(), defaults: UserDefaults = .standard) -> RingingSession? {
        guard let data = defaults.data(forKey: key),
              let session = try? JSONDecoder().decode(RingingSession.self, from: data) else { return nil }
        if now.timeIntervalSince(session.startedAt) > maxAge {
            defaults.removeObject(forKey: key)
            return nil
        }
        return session
    }

    static func save(_ session: RingingSession, defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(session) {
            defaults.set(data, forKey: key)
        }
    }

    static func clear(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }

    /// Starts a session. Returns true if a new one was created, false if one is already active.
    @discardableResult
    static func begin(now: Date = Date(), defaults: UserDefaults = .standard) -> Bool {
        if current(now: now, defaults: defaults) != nil { return false }
        save(RingingSession(startedAt: now, pendingAlarmIds: []), defaults: defaults)
        return true
    }
}
