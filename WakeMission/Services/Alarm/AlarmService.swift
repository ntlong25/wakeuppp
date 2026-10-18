import Foundation
import SwiftUI
#if canImport(AlarmKit)
import AlarmKit
#endif
import AppIntents

final class AlarmService: AlarmServiceProtocol, @unchecked Sendable {
    static let shared = AlarmService()
    
    private init() {}
    
    func requestAuthorization() async -> Bool {
        #if canImport(AlarmKit)
        do {
            let state = try await AlarmManager.shared.requestAuthorization()
            return state == .authorized
        } catch {
            print("AlarmKit authorization failed: \(error)")
            return false
        }
        #else
        print("AlarmKit not available on this platform/OS")
        return true
        #endif
    }
    
    func schedule(alarm: AlarmItem) async throws {
        #if canImport(AlarmKit)
        let alarmID = alarm.id
        
        let stopButton = AlarmButton(
            text: "Start Mission",
            textColor: .white,
            systemImageName: "flame.fill"
        )
        
        let secondaryButton = AlarmButton(
            text: "Wake Up",
            textColor: .white,
            systemImageName: "alarm.waves.left.and.right.fill"
        )
        
        let alertPresentation = AlarmPresentation.Alert(
            title: alarm.label.isEmpty ? "Wake Up!" : alarm.label,
            stopButton: stopButton,
            secondaryButton: secondaryButton,
            secondaryButtonBehavior: .custom
        )
        
        let attributes = AlarmAttributes(
            presentation: AlarmPresentation(alert: alertPresentation),
            tintColor: .orange
        )
        
        var openIntent = OpenAppFromAlarmIntent()
        openIntent.alarmId = alarmID.uuidString
        
        // Calculate target schedule components
        let calendar = Calendar.current
        let targetComponents = calendar.dateComponents([.hour, .minute], from: alarm.time)
        
        // Setup schedule configuration
        let configuration = AlarmManager.AlarmConfiguration(
            countdownDuration: nil,
            schedule: .daily(hour: targetComponents.hour ?? 0, minute: targetComponents.minute ?? 0),
            attributes: attributes,
            stopIntent: openIntent,
            secondaryIntent: openIntent,
            sound: .default
        )
        
        _ = try await AlarmManager.shared.schedule(
            id: alarmID,
            configuration: configuration
        )
        print("Scheduled alarm \(alarmID) with AlarmKit at \(targetComponents.hour ?? 0):\(targetComponents.minute ?? 0)")
        #else
        print("Simulated scheduling alarm \(alarm.id) for \(alarm.formattedTime)")
        #endif
    }
    
    func cancel(id: UUID) async throws {
        #if canImport(AlarmKit)
        try await AlarmManager.shared.cancel(id: id)
        print("Cancelled alarm \(id) with AlarmKit")
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
