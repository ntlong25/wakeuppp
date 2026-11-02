import Foundation
import SwiftUI
import AlarmKit
import AppIntents

nonisolated struct WakeMissionMetadata: AlarmMetadata {}

enum AlarmServiceError: Error {
    case noFireDate
}

/// Wraps AlarmKit. A user alarm fires first; every time an alert is dismissed before the missions are done,
/// `OpenAppFromAlarmIntent` arms one follow-up alarm, so at most one follow-up is pending at a time.
@MainActor
final class AlarmService: AlarmServiceProtocol {
    static let shared = AlarmService()

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

    func schedule(_ entry: AlarmEntry) async throws {
        try? await AlarmManager.shared.cancel(id: entry.id)

        let schedule: Alarm.Schedule
        if entry.repeatDays.isEmpty {
            guard let fireDate = entry.oneShotFireDate ?? entry.nextFireDate() else {
                throw AlarmServiceError.noFireDate
            }
            schedule = .fixed(fireDate)
        } else {
            schedule = .relative(
                Alarm.Schedule.Relative(
                    time: .init(hour: entry.hour, minute: entry.minute),
                    repeats: .weekly(entry.repeatDays.sorted().compactMap(Self.weekday(for:)))
                )
            )
        }

        try await submit(
            id: entry.id,
            title: LocalizedStringResource(stringLiteral: entry.displayLabel),
            isFollowUp: false,
            schedule: schedule
        )
    }

    func cancel(id: UUID) async throws {
        try await AlarmManager.shared.cancel(id: id)
    }

    func armNext(after delay: TimeInterval) async {
        guard var session = RingingStore.current() else { return }
        await cancel(ids: session.pendingAlarmIds)

        let id = UUID()
        do {
            try await submit(
                id: id,
                title: "Wake up! Finish your missions",
                isFollowUp: true,
                schedule: .fixed(Date().addingTimeInterval(delay))
            )
            session.pendingAlarmIds = [id]
        } catch {
            print("Failed to arm follow-up alarm: \(error)")
            session.pendingAlarmIds = []
        }
        RingingStore.save(session)
    }

    func cancelAll() async {
        guard var session = RingingStore.current() else { return }
        await cancel(ids: session.pendingAlarmIds)
        session.pendingAlarmIds = []
        RingingStore.save(session)
    }

    // MARK: - Private

    private func cancel(ids: [UUID]) async {
        for id in ids {
            try? await AlarmManager.shared.cancel(id: id)
        }
    }

    private func submit(id: UUID, title: LocalizedStringResource, isFollowUp: Bool, schedule: Alarm.Schedule) async throws {
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
            title: title,
            stopButton: stopButton,
            secondaryButton: secondaryButton,
            secondaryButtonBehavior: .custom
        )
        let attributes = AlarmAttributes<WakeMissionMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: WakeMissionMetadata(),
            tintColor: .orange
        )
        let intent = OpenAppFromAlarmIntent(isFollowUp: isFollowUp)
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
