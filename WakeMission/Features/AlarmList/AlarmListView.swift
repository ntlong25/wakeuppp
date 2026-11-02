import SwiftUI

/// Main screen, laid out like the Alarms tab of the Clock app.
struct AlarmListView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var alarmStore: AlarmStore
    @Environment(\.openURL) private var openURL

    @State private var isAdding = false
    @State private var editingAlarm: AlarmEntry?

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
                        Text("WakeMission needs alarm access to ring.")
                    }
                }

                ForEach(alarmStore.sortedAlarms) { alarm in
                    AlarmRow(alarm: alarm) {
                        editingAlarm = alarm
                    }
                }
                .onDelete { offsets in
                    let alarms = alarmStore.sortedAlarms
                    for index in offsets {
                        let alarm = alarms[index]
                        Task { await alarmStore.delete(alarm) }
                    }
                }
            }
            .overlay {
                if alarmStore.alarms.isEmpty {
                    ContentUnavailableView {
                        Label("No Alarms", systemImage: "alarm")
                    } description: {
                        Text("Tap + to add your first alarm.")
                    }
                }
            }
            .navigationTitle("Alarms")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !alarmStore.alarms.isEmpty { EditButton() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isAdding = true } label: {
                        Label("Add Alarm", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAdding) {
                AlarmEditView(alarm: nil)
            }
            .sheet(item: $editingAlarm) { alarm in
                AlarmEditView(alarm: alarm)
            }
            .alert("Couldn't Set Alarm", isPresented: $alarmStore.scheduleFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Check that alarms are allowed for WakeMission in Settings.")
            }
        }
    }
}

private struct AlarmRow: View {
    @EnvironmentObject var alarmStore: AlarmStore

    let alarm: AlarmEntry
    let onEdit: () -> Void

    private var timeText: String {
        let date = Calendar.current.date(bySettingHour: alarm.hour, minute: alarm.minute, second: 0, of: Date()) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(timeText)
                    .font(.system(size: 52, weight: .light))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(alarm.rowSubtitle)
                    .font(.subheadline)
                    .lineLimit(1)
            }
            .foregroundStyle(alarm.isEnabled ? Color.primary : Color.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onEdit)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Edit alarm")

            Toggle(isOn: Binding(
                get: { alarm.isEnabled },
                set: { enabled in Task { await alarmStore.setEnabled(enabled, for: alarm) } }
            )) {
                Text(alarm.rowSubtitle)
            }
            .labelsHidden()
        }
    }
}
