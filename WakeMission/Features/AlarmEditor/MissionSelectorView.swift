import SwiftUI

struct MissionSelectorView: View {
    @Binding var missions: [MissionDraft]
    @State private var showingAddSheet = false
    @State private var registeringMissionId: UUID?

    var body: some View {
        List {
            Section(header: Text("Configured Wake-Up Missions")) {
                if missions.isEmpty {
                    Text("No missions selected. A quick math task is used so the alarm can't be dismissed with a tap.")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                } else {
                    ForEach($missions) { $mission in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: mission.type.icon)
                                    .font(.title3)
                                    .foregroundColor(.orange)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mission.type.title)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text(mission.type.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                Picker("", selection: $mission.difficulty) {
                                    ForEach(MissionDifficulty.allCases) { diff in
                                        Text(diff.rawValue).tag(diff)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.orange)
                            }

                            if mission.type == .photo {
                                Button {
                                    registeringMissionId = mission.id
                                } label: {
                                    Label(
                                        mission.configurationData == nil ? "Register reference photo" : "Re-register reference photo",
                                        systemImage: mission.configurationData == nil ? "camera.badge.plus" : "checkmark.seal.fill"
                                    )
                                    .font(.caption.bold())
                                    .foregroundColor(.orange)
                                }
                                .buttonStyle(.plain)
                                if mission.configurationData == nil {
                                    Text("Without a reference, any bathroom sink scene is accepted.")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { missions.remove(atOffsets: $0) }
                    .onMove { missions.move(fromOffsets: $0, toOffset: $1) }
                }
            }

            Section {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Wake-Up Mission", systemImage: "plus.circle.fill")
                        .foregroundColor(.orange)
                        .font(.headline)
                }
            }
        }
        .navigationTitle("Wake-up Missions")
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
            List {
                ForEach(MissionType.allCases) { type in
                    Button {
                        onSelect(type)
                        dismiss()
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: type.icon)
                                .font(.title2)
                                .foregroundColor(.orange)
                                .frame(width: 40)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(type.title).font(.headline).foregroundColor(.white)
                                Text(type.subtitle).font(.caption).foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Choose Mission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
        .preferredColorScheme(.dark)
    }
}
