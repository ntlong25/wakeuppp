import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsStore: SettingsStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        MissionSelectorView(missions: $settingsStore.settings.missions)
                    } label: {
                        LabeledContent("Missions", value: missionsSummary)
                    }
                } footer: {
                    Text("These missions run for every alarm.")
                }

                Section {
                    Picker("Ring Again", selection: $settingsStore.settings.ringMode) {
                        ForEach(RingMode.allCases) { Text($0.title).tag($0) }
                    }
                } footer: {
                    Text("If you dismiss an alarm before finishing your missions, it keeps coming back at this pace, even if you close the app.")
                }

                Section {
                    Button("Test Wake-Up Flow") {
                        Task { await appState.startTestFlow() }
                    }
                } footer: {
                    Text("Starts your missions now, and the alarm rings again in a few seconds.")
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var missionsSummary: String {
        let missions = settingsStore.settings.missions
        return missions.isEmpty ? String(localized: "Quick math") : missions.map(\.type.title).joined(separator: ", ")
    }
}
