import Foundation
import SwiftUI

struct MissionStep: Identifiable, Equatable {
    let id = UUID()
    var type: MissionType
    var difficulty: MissionDifficulty
    var configurationData: Data?
}

/// Runs an alarm's missions in order. Completion callbacks are idempotent per step.
@MainActor
final class MissionCoordinator: ObservableObject {
    @Published private(set) var steps: [MissionStep]
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var isAllCompleted: Bool = false

    private var isAdvancing = false

    init(alarm: AlarmItem) {
        let configured = alarm.sortedMissions.map {
            MissionStep(type: $0.type, difficulty: $0.difficulty, configurationData: $0.configurationData)
        }
        // An alarm with no missions still needs one quick task so it cannot be dismissed with a tap.
        steps = configured.isEmpty ? [MissionStep(type: .math, difficulty: .easy)] : configured
    }

    var currentStep: MissionStep? {
        steps.indices.contains(currentIndex) ? steps[currentIndex] : nil
    }

    var totalMissionsCount: Int { steps.count }

    var currentStepDisplay: String {
        "Mission \(min(currentIndex + 1, totalMissionsCount)) of \(totalMissionsCount)"
    }

    var overallProgress: Double {
        guard totalMissionsCount > 0 else { return 1 }
        return isAllCompleted ? 1 : Double(currentIndex) / Double(totalMissionsCount)
    }

    /// Called by a mission view when it succeeds. Ignored unless `stepId` is the current, not-yet-completed step.
    func complete(stepId: UUID) {
        guard !isAdvancing, !isAllCompleted, currentStep?.id == stepId else { return }
        isAdvancing = true
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(600))
            guard let self else { return }
            if self.currentIndex + 1 < self.steps.count {
                self.currentIndex += 1
            } else {
                self.isAllCompleted = true
            }
            self.isAdvancing = false
        }
    }

    /// Escape hatch so a failing photo mission (camera denied, can't find target) never traps the user.
    func replaceWithMath(stepId: UUID) {
        guard !isAdvancing, let index = steps.firstIndex(where: { $0.id == stepId }) else { return }
        steps[index] = MissionStep(type: .math, difficulty: .medium)
    }
}
