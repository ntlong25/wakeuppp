import SwiftUI
import SwiftData

struct AlarmListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
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
                        headerSection

                        if !appState.isAlarmAuthorized && UserDefaults.standard.bool(forKey: "onboardingDone") {
                            permissionBanner
                        }

                        Divider().background(Color.white.opacity(0.12))

                        if alarms.isEmpty {
                            emptyStateView
                        } else {
                            VStack(spacing: 12) {
                                ForEach(alarms) { alarm in
                                    AlarmRowView(
                                        alarm: alarm,
                                        onToggle: { toggleAlarm(alarm, isEnabled: $0) },
                                        onSelect: { selectedAlarmForEdit = alarm }
                                    )
                                    .padding(.horizontal, 16)
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(16)
                                    .contextMenu {
                                        Button(role: .destructive) { delete(alarm) } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }

                        testSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("WakeMission").font(.title2.bold()).foregroundColor(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddSheet = true } label: {
                        Image(systemName: "plus").font(.title3.bold()).foregroundColor(.orange)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) { AlarmEditView(alarmToEdit: nil) }
            .sheet(item: $selectedAlarmForEdit) { AlarmEditView(alarmToEdit: $0) }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greetingText).font(.headline).foregroundColor(.gray)

            if let next = nextActiveAlarm {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(next.formattedTime)
                        .font(.system(size: 52, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text(next.timeRemainingText)
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

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Alarm permission is off", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.bold())
                .foregroundColor(.yellow)
            Text("WakeMission can't ring without AlarmKit access.")
                .font(.caption)
                .foregroundColor(.gray)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
            .font(.caption.bold())
            .foregroundColor(.orange)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "alarm.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange.opacity(0.6))
            Text("No wake-up alarms set").font(.headline).foregroundColor(.white)
            Text("Tap + to configure your first mission alarm.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var testSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick test")
                .font(.caption.bold())
                .foregroundColor(.gray)
                .textCase(.uppercase)

            Button(action: scheduleTestAlarm) {
                HStack {
                    Image(systemName: "bolt.fill").foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Test alarm in 1-2 minutes")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        Text("Schedules a one-shot alarm to check the lock-screen flow.")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
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
        if hour < 12 { return "Good morning" }
        if hour < 18 { return "Good afternoon" }
        return "Good evening"
    }

    /// Enabled alarm that fires soonest (not merely earliest on the clock).
    private var nextActiveAlarm: AlarmItem? {
        alarms
            .filter(\.isEnabled)
            .compactMap { alarm in alarm.nextFireDate.map { (alarm, $0) } }
            .min { $0.1 < $1.1 }?
            .0
    }

    private func toggleAlarm(_ alarm: AlarmItem, isEnabled: Bool) {
        alarm.isEnabled = isEnabled
        try? modelContext.save()
        let service = appState.alarmService
        let id = alarm.id
        Task { @MainActor in
            if isEnabled {
                try? await service.update(alarm: alarm)
            } else {
                try? await service.cancel(id: id)
            }
        }
    }

    private func delete(_ alarm: AlarmItem) {
        let id = alarm.id
        modelContext.delete(alarm)
        try? modelContext.save()
        let service = appState.alarmService
        Task { @MainActor in try? await service.cancel(id: id) }
    }

    private func scheduleTestAlarm() {
        let cal = Calendar.current
        // Next whole minute at least 60 s from now.
        let fire = cal.nextDate(
            after: Date().addingTimeInterval(60),
            matching: DateComponents(second: 0),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(90)

        let alarm = AlarmItem(
            time: fire,
            label: "Test Alarm",
            repeatDays: [],
            isEnabled: true,
            missions: [
                MissionItem(type: .typing, order: 0, difficulty: .easy),
                MissionItem(type: .math, order: 1, difficulty: .easy)
            ]
        )
        modelContext.insert(alarm)
        try? modelContext.save()

        let service = appState.alarmService
        Task { @MainActor in
            do { try await service.schedule(alarm: alarm) } catch { print("Test alarm failed: \(error)") }
        }
    }
}
