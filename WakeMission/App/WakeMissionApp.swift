import SwiftUI

@main
struct WakeMissionApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var settingsStore = SettingsStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(settingsStore)
                .task {
                    await appState.refreshAuthorizationIfOnboarded()
                    appState.consumePending()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { appState.consumePending() }
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
            HomeView()
        } else {
            OnboardingView { onboardingDone = true }
        }
    }
}
