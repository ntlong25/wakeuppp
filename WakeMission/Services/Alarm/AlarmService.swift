import Foundation
import SwiftUI
import AlarmKit
import AppIntents

nonisolated struct WakeMissionMetadata: AlarmMetadata {}

/// Arms WakeMission's own AlarmKit alarm after the user stops a Clock alarm.
/// At most one alarm is pending at a time; every time the user dismisses it,
/// `OpenAppFromAlarmIntent` arms the next one until the missions are done.
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

    func armNext(after delay: TimeInterval) async {
        guard var session = RingingStore.current() else { return }
        await cancel(ids: session.pendingAlarmIds)

        let id = UUID()
        do {
            try await submit(id: id, fireAt: Date().addingTimeInterval(delay))
            session.pendingAlarmIds = [id]
        } catch {
            print("Failed to arm wake alarm: \(error)")
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

    private func submit(id: UUID, fireAt: Date) async throws {
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
            title: LocalizedStringResource("Wake up! Finish your missions"),
            stopButton: stopButton,
            secondaryButton: secondaryButton,
            secondaryButtonBehavior: .custom
        )
        let attributes = AlarmAttributes<WakeMissionMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: WakeMissionMetadata(),
            tintColor: .orange
        )
        let intent = OpenAppFromAlarmIntent()
        let configuration = AlarmManager.AlarmConfiguration(
            countdownDuration: nil,
            schedule: .fixed(fireAt),
            attributes: attributes,
            stopIntent: intent,
            secondaryIntent: intent,
            sound: .default
        )
        _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
    }
}
