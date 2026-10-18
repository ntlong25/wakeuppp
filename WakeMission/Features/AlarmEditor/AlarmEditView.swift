import SwiftUI
import SwiftData

struct AlarmEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    
    let alarmToEdit: AlarmItem?
    
    @State private var selectedTime: Date = Date()
    @State private var label: String = "Morning Alarm"
    @State private var repeatDays: [Int] = [2, 3, 4, 5, 6] // Weekdays default
    @State private var soundName: String = "Radar"
    @State private var snoozeEnabled: Bool = false
    @State private var missions: [MissionItem] = []
    
    let availableSounds = ["Radar", "Beacon", "Chime", "Digital Siren", "Cosmic"]
    
    var body: some View {
        NavigationStack {
            Form {
                // Wheel Time Picker
                Section {
                    DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                // Repeat Days
                Section(header: Text("Repeat")) {
                    RepeatPicker(selectedDays: $repeatDays)
                        .padding(.vertical, 4)
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                // Alarm Details
                Section {
                    HStack {
                        Text("Label")
                        Spacer()
                        TextField("Alarm Label", text: $label)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.gray)
                    }
                    
                    Picker("Sound", selection: $soundName) {
                        ForEach(availableSounds, id: \.self) { sound in
                            Text(sound).tag(sound)
                        }
                    }
                    
                    Toggle("Snooze", isOn: $snoozeEnabled)
                        .tint(.orange)
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                // Missions Navigation
                Section {
                    NavigationLink(destination: MissionSelectorView(missions: $missions)) {
                        HStack {
                            Text("Wake-up Missions")
                            Spacer()
                            Text(missionsSummary)
                                .foregroundColor(.orange)
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
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.orange)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAlarm()
                    }
                    .font(.headline.bold())
                    .foregroundColor(.orange)
                }
            }
            .onAppear {
                loadInitialData()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var missionsSummary: String {
        if missions.isEmpty {
            return "None"
        }
        return "\(missions.count) mission\(missions.count > 1 ? "s" : "")"
    }
    
    private func loadInitialData() {
        if let alarm = alarmToEdit {
            selectedTime = alarm.time
            label = alarm.label
            repeatDays = alarm.repeatDays
            soundName = alarm.soundName
            snoozeEnabled = alarm.snoozeEnabled
            missions = alarm.missions
        } else {
            // Default new alarm with 1 Typing and 1 Math mission
            missions = [
                MissionItem(type: .typing, order: 0, difficulty: .easy),
                MissionItem(type: .math, order: 1, difficulty: .medium)
            ]
        }
    }
    
    private func saveAlarm() {
        if let alarm = alarmToEdit {
            alarm.time = selectedTime
            alarm.label = label
            alarm.repeatDays = repeatDays
            alarm.soundName = soundName
            alarm.snoozeEnabled = snoozeEnabled
            alarm.missions = missions
            
            Task { @MainActor in
                try? await appState.alarmService.update(alarm: alarm)
            }
        } else {
            let newAlarm = AlarmItem(
                time: selectedTime,
                label: label,
                repeatDays: repeatDays,
                isEnabled: true,
                soundName: soundName,
                snoozeEnabled: snoozeEnabled,
                missions: missions
            )
            modelContext.insert(newAlarm)
            
            Task { @MainActor in
                try? await appState.alarmService.schedule(alarm: newAlarm)
            }
        }
        
        try? modelContext.save()
        dismiss()
    }
}
