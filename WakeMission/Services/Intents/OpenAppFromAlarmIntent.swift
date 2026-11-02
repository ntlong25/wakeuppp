import Foundation
import AppIntents

extension Notification.Name {
    /// Posted (best effort) when the persisted ringing session changes while the app is alive.
    static let ringingSessionChanged = Notification.Name("com.wakemission.ringingSessionChanged")
}

/// Shared entry point for "the wake-up flow starts / continues".
@MainActor
enum WakeFlow {
    /// A user alarm was answered (or the test was started): start a session if needed and arm a follow-up.
    static func start() async {
        RingingStore.begin()
        await armFollowUp()
    }

    /// A follow-up alarm was dismissed: arm the next one unless the session has ended or expired.
    static func rearm() async {
        guard RingingStore.current() != nil else { return }
        await armFollowUp()
    }

    private static func armFollowUp() async {
        let delay = WakeSettings.load().ringMode.rearmDelay
        await AlarmService.shared.armNext(after: delay)
        NotificationCenter.default.post(name: .ringingSessionChanged, object: nil)
    }
}

/// Run by AlarmKit when the user taps a button on an alert. AlarmKit dismisses that alarm, so we arm the
/// next one right away (it only fires if the missions are still unfinished) and open the app.
struct OpenAppFromAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Wake Up & Start Mission" }
    static var description: IntentDescription { IntentDescription("Opens WakeMission to continue the wake-up missions.") }
    static var openAppWhenRun: Bool { true }

    @Parameter(title: "Follow-up")
    var isFollowUp: Bool

    init() {
        self.isFollowUp = false
    }

    init(isFollowUp: Bool) {
        self.isFollowUp = isFollowUp
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        if isFollowUp {
            await WakeFlow.rearm()
        } else {
            await WakeFlow.start()
        }
        return .result()
    }
}
