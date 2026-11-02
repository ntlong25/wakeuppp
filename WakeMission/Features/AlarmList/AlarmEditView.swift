import SwiftUI

/// Add/Edit Alarm sheet, laid out like the Clock app's editor.
struct AlarmEditView: View {
    @EnvironmentObject var alarmStore: AlarmStore
    @Environment(\.dismiss) private var dismiss

    private let original: AlarmEntry?
    @State private var time: Date
    @State private var label: String
    @State private var repeatDays: Set<Int>

    init(alarm: AlarmEntry?) {
        original = alarm
        let start = alarm.flatMap {
            Calendar.current.date(bySettingHour: $0.hour, minute: $0.minute, second: 0, of: Date())
        }
        _time = State(initialValue: start ?? Date())
        _label = State(initialValue: alarm?.label ?? "")
        _repeatDays = State(initialValue: alarm?.repeatDays ?? [])
    }

    private var repeatSummary: String {
        AlarmEntry(hour: 0, minute: 0, repeatDays: repeatDays).repeatSummary()
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)

                Section {
                    NavigationLink {
                        RepeatPickerView(selection: $repeatDays)
                    } label: {
                        LabeledContent("Repeat", value: repeatSummary)
                    }
                    LabeledContent("Label") {
                        TextField("Alarm", text: $label)
                            .multilineTextAlignment(.trailing)
                    }
                }

                if let original {
                    Section {
                        Button("Delete Alarm", role: .destructive) {
                            Task { await alarmStore.delete(original) }
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(original == nil ? "Add Alarm" : "Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
        var entry = original ?? AlarmEntry(hour: 0, minute: 0)
        entry.hour = parts.hour ?? 0
        entry.minute = parts.minute ?? 0
        entry.label = label.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.repeatDays = repeatDays
        Task { await alarmStore.save(entry) }
        dismiss()
    }
}

private struct RepeatPickerView: View {
    @Binding var selection: Set<Int>

    var body: some View {
        List(AlarmEntry.weekOrder(), id: \.self) { day in
            Button {
                if selection.contains(day) {
                    selection.remove(day)
                } else {
                    selection.insert(day)
                }
            } label: {
                HStack {
                    Text(Calendar.current.weekdaySymbols[day - 1])
                        .foregroundStyle(.primary)
                    Spacer()
                    if selection.contains(day) {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(.tint)
                    }
                }
            }
            .accessibilityAddTraits(selection.contains(day) ? .isSelected : [])
        }
        .navigationTitle("Repeat")
        .navigationBarTitleDisplayMode(.inline)
    }
}
