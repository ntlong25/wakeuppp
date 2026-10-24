import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var isAlarmAuthorized: Bool = false
    @Published var isRinging: Bool = false

    let alarmService: AlarmServiceProtocol
    private var observer: NSObjectProtocol?

    init(alarmService: AlarmServiceProtocol = AlarmService.shared) {
        self.alarmService = alarmService
        observer = NotificationCenter.default.addObserver(
            forName: .ringingSessionChanged, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.consumePending() }
        }
    }

    func requestAlarmAuthorization() async {
        isAlarmAuthorized = await alarmService.requestAuthorization()
    }

    /// After onboarding the system prompt has already been shown, so this just refreshes the status.
    func refreshAuthorizationIfOnboarded() async {
        guard UserDefaults.standard.bool(forKey: "onboardingDone") else { return }
        await requestAlarmAuthorization()
    }

    /// Shows the missions if a wake-up flow is in progress. Safe to call repeatedly.
    func consumePending() {
        guard !isRinging, RingingStore.current() != nil else { return }
        isRinging = true
    }

    /// Debug / "Try it now": behaves like the Shortcuts automation firing.
    func startTestFlow() async {
        await WakeFlow.start()
        consumePending()
    }

    func completeWakeUp() async {
        await alarmService.cancelAll()
        RingingStore.clear()
        isRinging = false
    }
}
