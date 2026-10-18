import Foundation
import SwiftUI

@MainActor
final class MissionCoordinator: ObservableObject {
    @Published var missions: [MissionItem] = []
    @Published var currentMissionIndex: Int = 0
    @Published var isAllCompleted: Bool = false
    @Published var currentMissionCompleted: Bool = false
    
    let alarm: AlarmItem
    private let onCompleteAll: () -> Void
    
    init(alarm: AlarmItem, onCompleteAll: @escaping () -> Void) {
        self.alarm = alarm
        self.onCompleteAll = onCompleteAll
        self.missions = alarm.missions.sorted(by: { $0.order < $1.order })
        
        // If no missions configured, default to a quick Math mission
        if self.missions.isEmpty {
            self.missions = [
                MissionItem(type: .math, order: 0, difficulty: .easy)
            ]
        }
    }
    
    var currentMission: MissionItem? {
        guard currentMissionIndex < missions.count else { return nil }
        return missions[currentMissionIndex]
    }
    
    var totalMissionsCount: Int {
        missions.count
    }
    
    var currentStepDisplay: String {
        "Mission \(currentMissionIndex + 1) of \(totalMissionsCount)"
    }
    
    var overallProgress: Double {
        guard totalMissionsCount > 0 else { return 1.0 }
        return Double(currentMissionIndex) / Double(totalMissionsCount)
    }
    
    func advanceToNextMission() {
        currentMissionCompleted = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self = self else { return }
            self.currentMissionCompleted = false
            if self.currentMissionIndex + 1 < self.missions.count {
                self.currentMissionIndex += 1
            } else {
                self.isAllCompleted = true
                self.onCompleteAll()
            }
        }
    }
}
