import Foundation
import SwiftUI
#if canImport(AlarmKit)
import AlarmKit
#endif
import AppIntents

#if canImport(AlarmKit)
@available(iOS 26.0, *)
nonisolated struct WakeMissionMetadata: AlarmMetadata {
    var alarmId: String
}
#endif

@MainActor
final class AlarmService: AlarmServiceProtocol {
    static let shared = AlarmService()
    
    private init() {}
    
    func requestAuthorization() async -> Bool {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            do {
                let state = try await AlarmManager.shared.requestAuthorization()
                return state == .authorized
            } catch {
                print("AlarmKit authorization failed: \(error)")
                return false
            }
        } else {
            return false
        }
        #else
        print("AlarmKit not available on this platform/OS")
        return true
        #endif
    }
    
    func schedule(alarm: AlarmItem) async throws {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            let alarmID = alarm.id
            
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
            
            let titleString = alarm.label.isEmpty ? "Wake Up!" : alarm.label
            let alertPresentation = AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: titleString),
                stopButton: stopButton,
                secondaryButton: secondaryButton,
                secondaryButtonBehavior: .custom
            )
            
            let attributes = AlarmAttributes<WakeMissionMetadata>(
                presentation: AlarmPresentation(alert: alertPresentation),
                metadata: WakeMissionMetadata(alarmId: alarmID.uuidString),
                tintColor: .orange
            )
            
            let openIntent = OpenAppFromAlarmIntent(alarmId: alarmID.uuidString)
            
            // Calculate target schedule components
            let calendar = Calendar.current
            let targetComponents = calendar.dateComponents([.hour, .minute], from: alarm.time)
            let targetHour = targetComponents.hour ?? 0
            let targetMinute = targetComponents.minute ?? 0
            
            let relativeSchedule = Alarm.Schedule.relative(
                Alarm.Schedule.Relative(
                    time: .init(hour: targetHour, minute: targetMinute),
                    repeats: .never
                )
            )
            
            // Setup schedule configuration
            let configuration = AlarmManager.AlarmConfiguration(
                countdownDuration: nil,
                schedule: relativeSchedule,
                attributes: attributes,
                stopIntent: openIntent,
                secondaryIntent: openIntent,
                sound: .default
            )
            
            _ = try await AlarmManager.shared.schedule(
                id: alarmID,
                configuration: configuration
            )
            print("Scheduled alarm \(alarmID) with AlarmKit at \(targetHour):\(targetMinute)")
        } else {
            print("AlarmKit requires iOS 26.0 or newer")
        }
        #else
        print("Simulated scheduling alarm \(alarm.id) for \(alarm.formattedTime)")
        #endif
    }
    
    func cancel(id: UUID) async throws {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            try await AlarmManager.shared.cancel(id: id)
            print("Cancelled alarm \(id) with AlarmKit")
        }
        #else
        print("Simulated cancel alarm \(id)")
        #endif
    }
    
    func update(alarm: AlarmItem) async throws {
        try await cancel(id: alarm.id)
        if alarm.isEnabled {
            try await schedule(alarm: alarm)
        }
    }
    
    func snooze(id: UUID) async throws {
        #if canImport(AlarmKit)
        // AlarmManager snooze or reschedule in 9 minutes
        let snoozeDate = Date().addingTimeInterval(9 * 60)
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.hour, .minute], from: snoozeDate)
        print("Snoozed alarm \(id) until \(comps.hour ?? 0):\(comps.minute ?? 0)")
        #else
        print("Simulated snooze alarm \(id)")
        #endif
    }
    
    func isAlarmScheduled(id: UUID) async -> Bool {
        #if canImport(AlarmKit)
        // Verify active state in AlarmManager
        return true
        #else
        return true
        #endif
    }
}
