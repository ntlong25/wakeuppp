import SwiftUI

/// Full-screen mission flow shown while a wake-up flow is in progress.
struct WakeUpContainerView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var coordinator: MissionCoordinator

    init(missions: [MissionDraft]) {
        _coordinator = StateObject(wrappedValue: MissionCoordinator(missions: missions))
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Divider()
                missionContent
            }

            if coordinator.isAllCompleted {
                ZStack {
                    Color(.systemBackground).opacity(0.95).ignoresSafeArea()
                    VStack(spacing: 16) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(.yellow)
                        Text("Good Morning!")
                            .font(.largeTitle.bold())
                        Text("All missions completed. You are awake.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .transition(.opacity)
            }
        }
        .tint(.orange)
        .onChange(of: coordinator.isAllCompleted) { _, completed in
            guard completed else { return }
            Task {
                try? await Task.sleep(for: .milliseconds(1200))
                await appState.completeWakeUp()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Wake Up")
                    .font(.title3.bold())
                Spacer()
                Text(coordinator.currentStepDisplay)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 16)

            ProgressView(value: coordinator.overallProgress)
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
