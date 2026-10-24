import Foundation
import AppIntents

/// Run by AlarmKit when the user taps "Start Mission" / "Wake Up" on the system alert.
/// AlarmKit dismisses the system alarm at this point, so we persist a ringing session
/// (the app may be cold-launched) and schedule backup nag alarms.
struct OpenAppFromAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Wake Up & Start Mission" }
    static var description: IntentDescription { IntentDescription("Launches WakeMission to begin wake-up missions.") }
    static var openAppWhenRun: Bool { true }

    @Parameter(title: "Alarm ID")
    var alarmId: String

    init() {
        self.alarmId = ""
    }

    init(alarmId: String) {
        self.alarmId = alarmId
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmId) else { return .result() }
        let isNewSession = RingingStore.begin(alarmId: uuid)
        if isNewSession {
            await AlarmService.shared.scheduleNags(parentId: uuid)
        }
        NotificationCenter.default.post(name: .ringingSessionChanged, object: nil)
        return .result()
    }
}

extension Notification.Name {
    /// Posted (best effort) when the persisted ringing session changes while the app is alive.
    static let ringingSessionChanged = Notification.Name("com.wakemission.ringingSessionChanged")
}
