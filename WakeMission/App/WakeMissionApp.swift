import SwiftUI

@main
struct WakeMissionApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var alarmStore = AlarmStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(settingsStore)
                .environmentObject(alarmStore)
                .task {
                    alarmStore.disableExpiredAlarms()
                    await appState.refreshAuthorizationIfOnboarded()
                    appState.consumePending()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        alarmStore.disableExpiredAlarms()
                        appState.consumePending()
                    }
                }
                .fullScreenCover(isPresented: $appState.isRinging) {
                    WakeUpContainerView(missions: settingsStore.settings.missions)
                        .environmentObject(appState)
                }
        }
    }
}

struct RootView: View {
    @AppStorage("onboardingDone") private var onboardingDone = false

    var body: some View {
        if onboardingDone {
            TabView {
                AlarmListView()
                    .tabItem { Label("Alarms", systemImage: "alarm.fill") }
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            }
        } else {
            OnboardingView { onboardingDone = true }
        }
    }
}
