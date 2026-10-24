import SwiftUI
import SwiftData

struct AlarmEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState

    let alarmToEdit: AlarmItem?

    @State private var selectedTime: Date = Date()
    @State private var label: String = "Morning Alarm"
    @State private var repeatDays: [Int] = [2, 3, 4, 5, 6]
    @State private var tone: AlarmTone = .classic
    @State private var missions: [MissionDraft] = []
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.white.opacity(0.05))

                Section(header: Text("Repeat")) {
                    RepeatPicker(selectedDays: $repeatDays)
                        .padding(.vertical, 4)
                }
                .listRowBackground(Color.white.opacity(0.05))

                Section {
                    HStack {
                        Text("Label")
                        Spacer()
                        TextField("Alarm Label", text: $label)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.gray)
                    }
                    Picker("Ringing tone", selection: $tone) {
                        ForEach(AlarmTone.allCases) { Text($0.rawValue).tag($0) }
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))

                Section {
                    NavigationLink(destination: MissionSelectorView(missions: $missions)) {
                        HStack {
                            Text("Wake-up Missions")
                            Spacer()
                            Text(missionsSummary).foregroundColor(.orange)
                        }
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle(alarmToEdit == nil ? "Add Alarm" : "Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.orange)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAlarm() }
                        .font(.headline.bold())
                        .foregroundColor(.orange)
                }
            }
            .onAppear { loadInitialData() }
        }
        .preferredColorScheme(.dark)
    }

    private var missionsSummary: String {
        missions.isEmpty ? "None" : "\(missions.count) mission\(missions.count > 1 ? "s" : "")"
    }

    private func loadInitialData() {
        guard !loaded else { return }
        loaded = true
        if let alarm = alarmToEdit {
            selectedTime = alarm.time
            label = alarm.label
            repeatDays = alarm.repeatDays
            tone = AlarmTone.from(alarm.soundName)
            missions = alarm.sortedMissions.map(\.draft)
        } else {
            missions = [
                MissionDraft(type: .typing, difficulty: .easy),
                MissionDraft(type: .math, difficulty: .medium)
            ]
        }
    }

    private func makeMissionItems() -> [MissionItem] {
        missions.enumerated().map { index, draft in
            MissionItem(type: draft.type, order: index, difficulty: draft.difficulty, configurationData: draft.configurationData)
        }
    }

    /// Strips seconds so the alarm fires at hh:mm:00.
    private var normalizedTime: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: selectedTime)
        return cal.date(from: comps) ?? selectedTime
    }

    private func saveAlarm() {
        let alarm: AlarmItem
        if let existing = alarmToEdit {
            alarm = existing
            alarm.time = normalizedTime
            alarm.label = label
            alarm.repeatDays = repeatDays
            alarm.soundName = tone.rawValue
            // Replace missions wholesale; delete the old ones so none are orphaned.
            let old = alarm.missions
            alarm.missions = makeMissionItems()
            old.forEach { modelContext.delete($0) }
        } else {
            alarm = AlarmItem(
                time: normalizedTime,
                label: label,
                repeatDays: repeatDays,
                isEnabled: true,
                soundName: tone.rawValue,
                missions: makeMissionItems()
            )
            modelContext.insert(alarm)
        }
        try? modelContext.save()

        let service = appState.alarmService
        Task { @MainActor in
            do {
                try await service.update(alarm: alarm)
            } catch {
                print("Failed to schedule alarm: \(error)")
            }
        }
        dismiss()
    }
}
