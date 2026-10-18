import Foundation
import AppIntents

struct StopAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Stop Alarm" }
    static var description: IntentDescription { IntentDescription("Stops the active ringing alarm after all missions have been successfully validated.") }
    static var openAppWhenRun: Bool { false }

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
            try? await AlarmService.shared.cancel(id: uuid)
            AlarmAudioPlayer.shared.stop()
        }
        return .result()
    }
}
