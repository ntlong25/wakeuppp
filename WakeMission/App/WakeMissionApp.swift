import SwiftUI
import SwiftData

@main
struct WakeMissionApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([AlarmItem.self, MissionItem.self, AlarmSessionRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .task {
                    appState.initialize(context: sharedModelContainer.mainContext)
                    await appState.requestAlarmAuthorizationIfOnboarded()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { appState.consumePending() }
                }
                .fullScreenCover(isPresented: $appState.isRinging) {
                    if let alarm = appState.activeRingingAlarm {
                        AlarmRingingContainerView(alarm: alarm)
                            .environmentObject(appState)
                            .preferredColorScheme(.dark)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

struct RootView: View {
    @AppStorage("onboardingDone") private var onboardingDone = false

    var body: some View {
        if onboardingDone {
            TabView {
                AlarmListView()
                    .tabItem { Label("Alarms", systemImage: "alarm.fill") }
                StatsView()
                    .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            }
            .tint(.orange)
        } else {
            OnboardingView { onboardingDone = true }
        }
    }
}
