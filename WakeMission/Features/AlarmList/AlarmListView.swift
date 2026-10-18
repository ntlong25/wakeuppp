import SwiftUI
import SwiftData

struct AlarmListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @Query(sort: \AlarmItem.time) private var alarms: [AlarmItem]
    
    @State private var showingAddSheet = false
    @State private var selectedAlarmForEdit: AlarmItem?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header Greeting & Next Alarm Banner
                        headerSection
                        
                        Divider()
                            .background(Color.white.opacity(0.12))
                        
                        // Alarm List Rows
                        if alarms.isEmpty {
                            emptyStateView
                        } else {
                            VStack(spacing: 12) {
                                ForEach(alarms) { alarm in
                                    AlarmRowView(
                                        alarm: alarm,
                                        onToggle: { isEnabled in
                                            toggleAlarm(alarm, isEnabled: isEnabled)
                                        },
                                        onSelect: {
                                            selectedAlarmForEdit = alarm
                                        }
                                    )
                                    .padding(.horizontal, 16)
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(16)
                                }
                            }
                        }
                        
                        // Milestone 0 Quick Test Section
                        milestoneTestSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("WakeMission")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title3.bold())
                            .foregroundColor(.orange)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AlarmEditView(alarmToEdit: nil)
            }
            .sheet(item: $selectedAlarmForEdit) { alarm in
                AlarmEditView(alarmToEdit: alarm)
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greetingText)
                .font(.headline)
                .foregroundColor(.gray)
            
            if let nextAlarm = nextActiveAlarm {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(nextAlarm.formattedTime)
                        .font(.system(size: 52, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(nextAlarm.timeRemainingText)
                        .font(.title3.bold())
                        .foregroundColor(.orange)
                }
            } else {
                Text("No Alarms Active")
                    .font(.title2.bold())
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "alarm.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange.opacity(0.6))
            Text("No wake-up alarms set")
                .font(.headline)
                .foregroundColor(.white)
            Text("Tap + to configure your first mission alarm.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Milestone 0 Test Helper
    private var milestoneTestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Milestone 0: AlarmKit Verification")
                .font(.caption.bold())
                .foregroundColor(.gray)
                .textCase(.uppercase)
            
            Button(action: scheduleMilestoneTestAlarm) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Test Alarm in 1 Minute")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        Text("Schedules an AlarmKit alert for T+60s to verify lock screen lifecycle.")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
            }
        }
        .padding(.top, 16)
    }
    
    // MARK: - Logic
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning ☀️" }
        if hour < 18 { return "Good afternoon 🌤️" }
        return "Good evening 👋"
    }
    
    private var nextActiveAlarm: AlarmItem? {
        alarms.first(where: { $0.isEnabled })
    }
    
    private func toggleAlarm(_ alarm: AlarmItem, isEnabled: Bool) {
        alarm.isEnabled = isEnabled
        try? modelContext.save()
        Task {
            if isEnabled {
                try? await appState.alarmService.schedule(alarm: alarm)
            } else {
                try? await appState.alarmService.cancel(id: alarm.id)
            }
        }
    }
    
    private func scheduleMilestoneTestAlarm() {
        let testTime = Date().addingTimeInterval(65)
        let testAlarm = AlarmItem(
            time: testTime,
            label: "Test Alarm (Milestone 0)",
            repeatDays: [],
            isEnabled: true,
            soundName: "Radar",
            snoozeEnabled: false,
            missions: [
                MissionItem(type: .typing, order: 0, difficulty: .easy),
                MissionItem(type: .math, order: 1, difficulty: .easy)
            ]
        )
        modelContext.insert(testAlarm)
        try? modelContext.save()
        
        Task {
            try? await appState.alarmService.schedule(alarm: testAlarm)
        }
    }
}
