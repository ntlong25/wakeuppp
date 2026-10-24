import SwiftUI

struct MissionSelectorView: View {
    @Binding var missions: [MissionDraft]
    @State private var showingAddSheet = false
    @State private var registeringMissionId: UUID?

    var body: some View {
        List {
            Section {
                if missions.isEmpty {
                    Text("No missions selected. A quick math task is used so the alarm can't be dismissed with a tap.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach($missions) { $mission in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: mission.type.icon)
                                    .font(.title3)
                                    .foregroundStyle(.orange)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mission.type.title)
                                    Text(mission.type.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Picker("Difficulty", selection: $mission.difficulty) {
                                    ForEach(MissionDifficulty.allCases) { Text($0.rawValue).tag($0) }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                            }

                            if mission.type == .photo {
                                Button {
                                    registeringMissionId = mission.id
                                } label: {
                                    Label(
                                        mission.configurationData == nil ? "Register reference photo" : "Re-register reference photo",
                                        systemImage: mission.configurationData == nil ? "camera.badge.plus" : "checkmark.seal.fill"
                                    )
                                    .font(.subheadline)
                                }
                                .buttonStyle(.borderless)
                                if mission.configurationData == nil {
                                    Text("Without a reference, any bathroom sink scene is accepted.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete { missions.remove(atOffsets: $0) }
                    .onMove { missions.move(fromOffsets: $0, toOffset: $1) }
                }
            } footer: {
                Text("Missions run in this order. Drag to reorder with Edit.")
            }

            Section {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Mission", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("Missions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .sheet(isPresented: $showingAddSheet) {
            AddMissionSheet { newType in
                missions.append(MissionDraft(type: newType))
            }
        }
        .sheet(isPresented: Binding(
            get: { registeringMissionId != nil },
            set: { if !$0 { registeringMissionId = nil } }
        )) {
            ReferenceRegistrationView { config in
                if let id = registeringMissionId,
                   let index = missions.firstIndex(where: { $0.id == id }) {
                    missions[index].configurationData = config.encoded()
                }
            }
        }
    }
}

struct AddMissionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (MissionType) -> Void

    var body: some View {
        NavigationStack {
            List(MissionType.allCases) { type in
                Button {
                    onSelect(type)
                    dismiss()
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: type.icon)
                            .font(.title2)
                            .foregroundStyle(.orange)
                            .frame(width: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.title).foregroundStyle(.primary)
                            Text(type.subtitle).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Choose Mission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}
