import Foundation
import SwiftUI
import AlarmKit
import AppIntents

nonisolated struct WakeMissionMetadata: AlarmMetadata {
    var alarmId: String
}

enum AlarmServiceError: Error {
    case noFireDate
}

@MainActor
final class AlarmService: AlarmServiceProtocol {
    static let shared = AlarmService()

    /// Backup alarms: +3, +6 … +18 minutes after the user first taps the system alert.
    static let nagCount = 6
    static let nagInterval: TimeInterval = 3 * 60

    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            let state = try await AlarmManager.shared.requestAuthorization()
            return state == .authorized
        } catch {
            print("AlarmKit authorization failed: \(error)")
            return false
        }
    }

    func schedule(alarm: AlarmItem) async throws {
        guard alarm.isEnabled else { return }
        guard let fireDate = alarm.nextFireDate else { throw AlarmServiceError.noFireDate }

        // Replace any previous schedule for this id.
        try? await AlarmManager.shared.cancel(id: alarm.id)

        let title = alarm.label.isEmpty ? "Wake Up!" : alarm.label
        let schedule: Alarm.Schedule
        if alarm.repeatDays.isEmpty {
            schedule = .fixed(fireDate)
        } else {
            let hm = Calendar.current.dateComponents([.hour, .minute], from: alarm.time)
            let weekdays = Set(alarm.repeatDays).sorted().compactMap(Self.weekday(for:))
            schedule = .relative(
                Alarm.Schedule.Relative(
                    time: .init(hour: hm.hour ?? 0, minute: hm.minute ?? 0),
                    repeats: .weekly(weekdays)
                )
            )
        }

        try await submit(id: alarm.id, title: title, parentId: alarm.id, schedule: schedule)
    }

    func cancel(id: UUID) async throws {
        try await AlarmManager.shared.cancel(id: id)
    }

    func update(alarm: AlarmItem) async throws {
        try? await cancel(id: alarm.id)
        if alarm.isEnabled {
            try await schedule(alarm: alarm)
        }
    }

    func scheduleNags(parentId: UUID) async {
        guard var session = RingingStore.current(), session.alarmId == parentId else { return }
        var ids: [UUID] = []
        for i in 1...Self.nagCount {
            let id = UUID()
            let date = Date().addingTimeInterval(Self.nagInterval * Double(i))
            do {
                try await submit(id: id, title: "Still asleep? Finish your missions", parentId: parentId, schedule: .fixed(date))
                ids.append(id)
            } catch {
                print("Failed to schedule nag \(i): \(error)")
            }
        }
        session.nagIds = ids
        RingingStore.save(session)
    }

    func cancelNags() async {
        guard var session = RingingStore.current() else { return }
        for id in session.nagIds {
            try? await AlarmManager.shared.cancel(id: id)
        }
        session.nagIds = []
        RingingStore.save(session)
    }

    // MARK: - Private

    private func submit(id: UUID, title: String, parentId: UUID, schedule: Alarm.Schedule) async throws {
        let stopButton = AlarmButton(
            text: LocalizedStringResource("Start Mission"),
            textColor: .white,
            systemImageName: "flame.fill"
        )
        let secondaryButton = AlarmButton(
            text: LocalizedStringResource("Wake Up"),
            textColor: .white,
            systemImageName: "alarm.waves.left.and.right.fill"
        )
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: title),
            stopButton: stopButton,
            secondaryButton: secondaryButton,
            secondaryButtonBehavior: .custom
        )
        let attributes = AlarmAttributes<WakeMissionMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: WakeMissionMetadata(alarmId: parentId.uuidString),
            tintColor: .orange
        )
        let intent = OpenAppFromAlarmIntent(alarmId: parentId.uuidString)
        let configuration = AlarmManager.AlarmConfiguration(
            countdownDuration: nil,
            schedule: schedule,
            attributes: attributes,
            stopIntent: intent,
            secondaryIntent: intent,
            sound: .default
        )
        _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
    }

    private static func weekday(for day: Int) -> Locale.Weekday? {
        switch day {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return nil
        }
    }
}
