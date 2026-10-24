import SwiftUI

struct AlarmRingingContainerView: View {
    @EnvironmentObject var appState: AppState

    let alarm: AlarmItem
    @StateObject private var coordinator: MissionCoordinator

    init(alarm: AlarmItem) {
        self.alarm = alarm
        _coordinator = StateObject(wrappedValue: MissionCoordinator(alarm: alarm))
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                header
                Divider().background(Color.white.opacity(0.1))
                missionContent
            }

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
        .onChange(of: coordinator.isAllCompleted) { _, completed in
            guard completed else { return }
            Task {
                try? await Task.sleep(for: .milliseconds(1200))
                await appState.completeAlarm(missionsCompleted: coordinator.totalMissionsCount)
            }
        }
    }

    private var header: some View {
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
                HStack(spacing: 4) {
                    Image(systemName: "speaker.wave.3.fill")
                    Text("RINGING").font(.caption.bold())
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.top, 16)

            ProgressView(value: coordinator.overallProgress)
                .tint(.orange)
                .padding(.horizontal)
                .animation(.spring(), value: coordinator.overallProgress)
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var missionContent: some View {
        if let step = coordinator.currentStep {
            Group {
                switch step.type {
                case .typing:
                    TypingMissionView(difficulty: step.difficulty) {
                        coordinator.complete(stepId: step.id)
                    }
                case .math:
                    MathMissionView(difficulty: step.difficulty) {
                        coordinator.complete(stepId: step.id)
                    }
                case .photo:
                    PhotoMissionView(
                        difficulty: step.difficulty,
                        configurationData: step.configurationData,
                        onCompleted: { coordinator.complete(stepId: step.id) },
                        onFallback: { coordinator.replaceWithMath(stepId: step.id) }
                    )
                }
            }
            .id(step.id)
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        }
    }
}
