import Foundation

/// How soon the system alarm rings again after the user dismisses it without finishing the missions.
enum RingMode: Int, CaseIterable, Identifiable, Codable, Sendable {
    case every5 = 5
    case every10 = 10
    case every30 = 30
    case every60 = 60
    case continuous = 0

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .every5: return "Every 5 seconds"
        case .every10: return "Every 10 seconds"
        case .every30: return "Every 30 seconds"
        case .every60: return "Every minute"
        case .continuous: return "Continuous"
        }
    }

    /// Delay before the next system alarm is armed. "Continuous" re-arms as fast as practical.
    var rearmDelay: TimeInterval {
        self == .continuous ? 2 : TimeInterval(rawValue)
    }
}

/// Global wake-up configuration (one mission sequence for every Clock alarm).
struct WakeSettings: Codable, Equatable, Sendable {
    var missions: [MissionDraft]
    var ringMode: RingMode

    static let `default` = WakeSettings(
        missions: [
            MissionDraft(type: .typing, difficulty: .easy),
            MissionDraft(type: .math, difficulty: .medium)
        ],
        ringMode: .every5
    )

    private static let key = "com.wakemission.settings"

    /// Thread-safe read (used by App Intents, which may run before the UI exists).
    static func load(defaults: UserDefaults = .standard) -> WakeSettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(WakeSettings.self, from: data) else { return .default }
        return settings
    }

    func save(defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(self) {
            defaults.set(data, forKey: Self.key)
        }
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    @Published var settings: WakeSettings {
        didSet { settings.save() }
    }

    init() {
        settings = WakeSettings.load()
    }
}
