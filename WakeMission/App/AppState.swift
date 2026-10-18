import Foundation
import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isAlarmAuthorized: Bool = false
    @Published var isRinging: Bool = false
    @Published var activeRingingAlarm: AlarmItem?
    @Published var errorMessage: String?
    
    let alarmService: AlarmServiceProtocol
    let audioPlayer: AlarmAudioPlayer
    
    init(
        alarmService: AlarmServiceProtocol = AlarmService.shared,
        audioPlayer: AlarmAudioPlayer = AlarmAudioPlayer.shared
    ) {
        self.alarmService = alarmService
        self.audioPlayer = audioPlayer
    }
    
    func initialize() async {
        isAlarmAuthorized = await alarmService.requestAuthorization()
        setupAlarmNotificationObserver()
    }
    
    func triggerAlarm(with alarm: AlarmItem) {
        self.activeRingingAlarm = alarm
        self.isRinging = true
        self.audioPlayer.playLooping(soundName: alarm.soundName)
    }
    
    func completeAlarm() {
        self.audioPlayer.stop()
        self.isRinging = false
        if let alarm = activeRingingAlarm {
            Task {
                try? await alarmService.cancel(id: alarm.id)
            }
        }
        self.activeRingingAlarm = nil
    }
    
    private func setupAlarmNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: .alarmDidTriggerNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let alarmId = notification.userInfo?["alarmId"] as? UUID else { return }
            // Notification handling for alarm triggered via intent
            Task {
                await self.handleAlarmTriggered(alarmId: alarmId)
            }
        }
    }
    
    private func handleAlarmTriggered(alarmId: UUID) async {
        // Active alarm lookup can be populated from SwiftData or cached items
        print("Handling alarm trigger from AlarmKit: \(alarmId)")
    }
}

extension Notification.Name {
    static let alarmDidTriggerNotification = Notification.Name("com.wakemission.alarmDidTrigger")
}
