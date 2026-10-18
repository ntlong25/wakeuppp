import SwiftUI
import SwiftData

struct AlarmRingingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    
    let alarm: AlarmItem
    @StateObject private var coordinator: MissionCoordinator
    @State private var startTime = Date()
    
    init(alarm: AlarmItem) {
        self.alarm = alarm
        // Pre-create coordinator
        _coordinator = StateObject(wrappedValue: MissionCoordinator(alarm: alarm, onCompleteAll: {}))
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Top Mission Stepper
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(alarm.label.isEmpty ? "Wake Up" : alarm.label)
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            Text(coordinator.currentStepDisplay)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        
                        // Volume active indicator
                        HStack(spacing: 4) {
                            Image(systemName: "speaker.wave.3.fill")
                                .foregroundColor(.orange)
                            Text("RINGING")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Stepper Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                            Capsule()
                                .fill(Color.orange)
                                .frame(width: geo.size.width * CGFloat(coordinator.overallProgress))
                                .animation(.spring(), value: coordinator.overallProgress)
                        }
                    }
                    .frame(height: 6)
                    .padding(.horizontal)
                }
                .padding(.bottom, 12)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Active Mission Content
                if let currentMission = coordinator.currentMission {
                    Group {
                        switch currentMission.type {
                        case .typing:
                            TypingMissionView(
                                difficulty: currentMission.difficulty,
                                onCompleted: {
                                    coordinator.advanceToNextMission()
                                }
                            )
                        case .math:
                            MathMissionView(
                                difficulty: currentMission.difficulty,
                                onCompleted: {
                                    coordinator.advanceToNextMission()
                                }
                            )
                        case .photo:
                            PhotoMissionView(
                                difficulty: currentMission.difficulty,
                                onCompleted: {
                                    coordinator.advanceToNextMission()
                                }
                            )
                        }
                    }
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    .animation(.easeInOut(duration: 0.3), value: coordinator.currentMissionIndex)
                }
            }
            
            // Completion Overlay Animation
            if coordinator.isAllCompleted {
                ZStack {
                    Color.black.opacity(0.85).edgesIgnoringSafeArea(.all)
                    VStack(spacing: 16) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 72))
                            .foregroundColor(.yellow)
                        Text("Good Morning!")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        Text("All missions completed. You are awake.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            self.startTime = Date()
        }
        .onChange(of: coordinator.isAllCompleted) { _, completed in
            if completed {
                recordSessionCompletion()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    appState.completeAlarm()
                }
            }
        }
    }
    
    private func recordSessionCompletion() {
        let duration = Date().timeIntervalSince(startTime)
        let record = AlarmSessionRecord(
            alarmId: alarm.id,
            scheduledAt: alarm.time,
            triggeredAt: startTime,
            completedAt: Date(),
            missionsCompleted: coordinator.totalMissionsCount,
            durationSeconds: duration,
            snoozeCount: 0,
            success: true
        )
        modelContext.insert(record)
        try? modelContext.save()
    }
}
