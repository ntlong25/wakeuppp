import SwiftUI

struct MissionSelectorView: View {
    @Binding var missions: [MissionItem]
    @State private var showingAddSheet = false
    
    var body: some View {
        List {
            Section(header: Text("Configured Wake-Up Missions")) {
                if missions.isEmpty {
                    Text("No missions selected. Alarm will turn off with a tap.")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                } else {
                    ForEach($missions) { $mission in
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
                            
                            // Difficulty picker
                            Picker("", selection: $mission.difficulty) {
                                ForEach(MissionDifficulty.allCases) { diff in
                                    Text(diff.rawValue).tag(diff)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.orange)
                        }
                    }
                    .onDelete(perform: deleteMission)
                    .onMove(perform: moveMission)
                }
            }
            
            Section {
                Button(action: {
                    showingAddSheet = true
                }) {
                    Label("Add Wake-Up Mission", systemImage: "plus.circle.fill")
                        .foregroundColor(.orange)
                        .font(.headline)
                }
            }
        }
        .navigationTitle("Wake-up Missions")
        .toolbar {
            EditButton()
        }
        .sheet(isPresented: $showingAddSheet) {
            AddMissionSheet { newType in
                let newOrder = missions.count
                let newMission = MissionItem(type: newType, order: newOrder, difficulty: .medium)
                missions.append(newMission)
            }
        }
    }
    
    private func deleteMission(at offsets: IndexSet) {
        missions.remove(atOffsets: offsets)
        reindexOrders()
    }
    
    private func moveMission(from source: IndexSet, to destination: Int) {
        missions.move(fromOffsets: source, toOffset: destination)
        reindexOrders()
    }
    
    private func reindexOrders() {
        for index in 0..<missions.count {
            missions[index].order = index
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
                    Button(action: {
                        onSelect(type)
                        dismiss()
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: type.icon)
                                .font(.title2)
                                .foregroundColor(.orange)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(type.title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(type.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Choose Mission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
