import Foundation
import SwiftUI
import SwiftData

@MainActor
final class AppState: ObservableObject {
    @Published var isAlarmAuthorized: Bool = false
    @Published var isRinging: Bool = false
    @Published var activeRingingAlarm: AlarmItem?

    let alarmService: AlarmServiceProtocol
    let audioPlayer: AlarmAudioPlayer

    private var context: ModelContext?
    private var activeRecord: AlarmSessionRecord?
    private var observer: NSObjectProtocol?

    init(
        alarmService: AlarmServiceProtocol = AlarmService.shared,
        audioPlayer: AlarmAudioPlayer = AlarmAudioPlayer.shared
    ) {
        self.alarmService = alarmService
        self.audioPlayer = audioPlayer
    }

    /// Attach the model context and pick up any alarm the user already tapped on the lock screen.
    func initialize(context: ModelContext) {
        guard self.context == nil else { return }
        self.context = context
        observer = NotificationCenter.default.addObserver(
            forName: .ringingSessionChanged, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.consumePending() }
        }
        consumePending()
    }

    /// After onboarding the system prompt has already been shown, so this just refreshes the status.
    func requestAlarmAuthorizationIfOnboarded() async {
        guard UserDefaults.standard.bool(forKey: "onboardingDone") else { return }
        await requestAlarmAuthorization()
    }

    func requestAlarmAuthorization() async {
        isAlarmAuthorized = await alarmService.requestAuthorization()
    }

    /// Starts (or resumes) ringing if the intent persisted a session. Safe to call repeatedly.
    func consumePending() {
        guard !isRinging, let context, let session = RingingStore.current() else { return }

        let alarmId = session.alarmId
        let descriptor = FetchDescriptor<AlarmItem>(predicate: #Predicate { $0.id == alarmId })
        guard let alarm = try? context.fetch(descriptor).first else {
            // Alarm was deleted while ringing: clean up.
            Task { await alarmService.cancelNags(); RingingStore.clear() }
            return
        }

        var updated = session
        let record: AlarmSessionRecord
        if let rid = session.recordId,
           let existing = try? context.fetch(FetchDescriptor<AlarmSessionRecord>(predicate: #Predicate { $0.id == rid })).first {
            record = existing
        } else {
            record = AlarmSessionRecord(
                alarmId: alarm.id,
                scheduledAt: alarm.nextFireDate ?? session.startedAt,
                triggeredAt: session.startedAt
            )
            context.insert(record)
            updated.recordId = record.id
            RingingStore.save(updated)
            try? context.save()
        }

        activeRecord = record
        activeRingingAlarm = alarm
        isRinging = true
        audioPlayer.playLooping(tone: AlarmTone.from(alarm.soundName))
    }

    func completeAlarm(missionsCompleted: Int) async {
        audioPlayer.stop()
        await alarmService.cancelNags()

        if let record = activeRecord {
            let now = Date()
            record.completedAt = now
            record.missionsCompleted = missionsCompleted
            record.durationSeconds = now.timeIntervalSince(record.triggeredAt)
            record.success = true
        }
        if let alarm = activeRingingAlarm, alarm.repeatDays.isEmpty {
            // One-shot: AlarmKit already removed it after firing; just reflect that in the UI.
            alarm.isEnabled = false
        }
        try? context?.save()

        RingingStore.clear()
        activeRecord = nil
        activeRingingAlarm = nil
        isRinging = false
    }
}
