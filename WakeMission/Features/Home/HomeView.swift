import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsStore: SettingsStore
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Label("Alarms", systemImage: "alarm.fill")
                        Spacer()
                        if appState.isAlarmAuthorized {
                            Text("Allowed").foregroundStyle(.secondary)
                        } else {
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                            }
                        }
                    }
                } header: {
                    Text("Permission")
                } footer: {
                    if !appState.isAlarmAuthorized {
                        Text("WakeMission needs alarm access to ring again until you finish your missions.")
                    }
                }

                Section {
                    NavigationLink {
                        MissionSelectorView(missions: $settingsStore.settings.missions)
                    } label: {
                        LabeledContent("Missions", value: missionsSummary)
                    }
                } header: {
                    Text("Wake-up")
                } footer: {
                    Text("These missions run every time you stop a Clock alarm.")
                }

                Section {
                    Picker("Ring again", selection: $settingsStore.settings.ringMode) {
                        ForEach(RingMode.allCases) { Text($0.title).tag($0) }
                    }
                } header: {
                    Text("If you dismiss the alarm")
                } footer: {
                    Text("Until the missions are done, the system alarm rings again after this delay - even if you close the app.")
                }

                Section {
                    NavigationLink("Connect to the Clock app") { ShortcutsGuideView() }
                    Button("Try it now") {
                        Task { await appState.startTestFlow() }
                    }
                } header: {
                    Text("Setup")
                } footer: {
                    Text("\"Try it now\" behaves like stopping a Clock alarm: the alarm rings in a few seconds.")
                }
            }
            .navigationTitle("WakeMission")
        }
        .tint(.orange)
    }

    private var missionsSummary: String {
        let count = settingsStore.settings.missions.count
        return count == 0 ? "None" : "\(count)"
    }
}
