import Foundation
import AppIntents

extension Notification.Name {
    /// Posted (best effort) when the persisted ringing session changes while the app is alive.
    static let ringingSessionChanged = Notification.Name("com.wakemission.ringingSessionChanged")
}

/// Shared entry point for "the wake-up flow starts / continues".
@MainActor
enum WakeFlow {
    /// Starts a session (if none) and arms the first WakeMission alarm.
    static func start() async {
        RingingStore.begin()
        let delay = WakeSettings.load().ringMode.rearmDelay
        await AlarmService.shared.armNext(after: delay)
        NotificationCenter.default.post(name: .ringingSessionChanged, object: nil)
    }

    /// Called when the user dismisses a WakeMission alarm: arm the next one unless the session is gone.
    static func rearm() async {
        guard RingingStore.current() != nil else { return }
        let delay = WakeSettings.load().ringMode.rearmDelay
        await AlarmService.shared.armNext(after: delay)
        NotificationCenter.default.post(name: .ringingSessionChanged, object: nil)
    }
}

/// Run by AlarmKit when the user taps a button on a WakeMission alert. AlarmKit dismisses that alarm,
/// so we arm the next one right away (it only fires if the missions are still unfinished) and open the app.
struct OpenAppFromAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Wake Up & Start Mission" }
    static var description: IntentDescription { IntentDescription("Opens WakeMission to continue the wake-up missions.") }
    static var openAppWhenRun: Bool { true }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        await WakeFlow.rearm()
        return .result()
    }
}

/// Exposed to Shortcuts. Used by the automation "When alarm is stopped" -> "Start Wake-up Missions".
struct StartWakeMissionsIntent: AppIntent {
    static var title: LocalizedStringResource { "Start Wake-up Missions" }
    static var description: IntentDescription {
        IntentDescription("Starts WakeMission's wake-up flow. The alarm rings again until you finish your missions.")
    }
    static var openAppWhenRun: Bool { false }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        await WakeFlow.start()
        return .result()
    }
}

struct WakeMissionShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartWakeMissionsIntent(),
            phrases: ["Start wake-up missions with \(.applicationName)"],
            shortTitle: "Start Wake-up Missions",
            systemImageName: "alarm.fill"
        )
    }
}
