import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsStore: SettingsStore
    @Environment(\.openURL) private var openURL
    @AppStorage("clockSetupDone") private var clockSetupDone = false

    var body: some View {
        NavigationStack {
            List {
                if appState.authorizationKnown && !appState.isAlarmAuthorized {
                    Section {
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        }
                    } header: {
                        Text("Alarms are turned off")
                    } footer: {
                        Text("WakeMission needs alarm access to ring again until you finish your missions.")
                    }
                }

                if !clockSetupDone {
                    Section {
                        clockSetupLink
                    } header: {
                        Text("Finish setup")
                    } footer: {
                        Text("Missions only start after you connect your Clock alarms.")
                    }
                }

                Section {
                    NavigationLink {
                        MissionSelectorView(missions: $settingsStore.settings.missions)
                    } label: {
                        LabeledContent("Missions", value: missionsSummary)
                    }
                    Picker("Ring Again", selection: $settingsStore.settings.ringMode) {
                        ForEach(RingMode.allCases) { Text($0.title).tag($0) }
                    }
                } footer: {
                    Text("After you stop a Clock alarm, the alarm keeps coming back at this pace until your missions are done, even if you close the app.")
                }

                Section {
                    if clockSetupDone {
                        clockSetupLink
                    }
                    Button("Test Wake-Up Flow") {
                        Task { await appState.startTestFlow() }
                    }
                } footer: {
                    Text("The test works like stopping a Clock alarm, so the alarm will ring in a few seconds.")
                }
            }
            .navigationTitle("WakeMission")
        }
    }

    private var clockSetupLink: some View {
        NavigationLink("Connect to Clock") { ShortcutsGuideView() }
    }

    private var missionsSummary: String {
        let missions = settingsStore.settings.missions
        return missions.isEmpty ? "Quick math" : missions.map(\.type.title).joined(separator: ", ")
    }
}
