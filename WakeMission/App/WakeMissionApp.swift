import SwiftUI
import SwiftData
#if canImport(AlarmKit)
import AlarmKit
#endif

@main
struct WakeMissionApp: App {
    @StateObject private var appState = AppState()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AlarmItem.self,
            MissionItem.self,
            AlarmSessionRecord.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .task {
                    await appState.initialize()
                }
                .fullScreenCover(isPresented: $appState.isRinging) {
                    if let ringingAlarm = appState.activeRingingAlarm {
                        AlarmRingingContainerView(alarm: ringingAlarm)
                            .environmentObject(appState)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        AlarmListView()
            .preferredColorScheme(.dark)
    }
}
