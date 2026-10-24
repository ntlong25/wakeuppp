import Foundation

/// The alarm currently being "worked on" (system alert tapped, missions not finished).
/// Persisted in UserDefaults so an App Intent can hand off to a cold-launched app.
struct RingingSession: Codable, Equatable, Sendable {
    var alarmId: UUID
    var startedAt: Date
    var recordId: UUID?
    var nagIds: [UUID]
}

enum RingingStore {
    private static let key = "com.wakemission.ringingSession"
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

    /// Starts a session for `alarmId`. Returns true if a new session was created,
    /// false if one for the same alarm was already active (e.g. a nag alarm was tapped).
    @discardableResult
    static func begin(alarmId: UUID, now: Date = Date(), defaults: UserDefaults = .standard) -> Bool {
        if let existing = current(now: now, defaults: defaults), existing.alarmId == alarmId {
            return false
        }
        save(RingingSession(alarmId: alarmId, startedAt: now, recordId: nil, nagIds: []), defaults: defaults)
        return true
    }
}
