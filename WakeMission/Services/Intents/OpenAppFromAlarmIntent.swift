import Foundation
import AppIntents

struct OpenAppFromAlarmIntent: AppIntent {
    static var title: LocalizedStringResource = "Wake Up & Start Mission"
    static var description = IntentDescription("Launches WakeMission into the foreground to begin wake-up missions.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Alarm ID")
    var alarmId: String?

    init() {
        self.alarmId = nil
    }
    
    init(alarmId: String) {
        self.alarmId = alarmId
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        if let idString = alarmId, let uuid = UUID(uuidString: idString) {
            NotificationCenter.default.post(
                name: .alarmDidTriggerNotification,
                object: nil,
                userInfo: ["alarmId": uuid]
            )
        }
        return .result()
    }
}
