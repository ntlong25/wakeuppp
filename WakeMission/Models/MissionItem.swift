import Foundation
import SwiftData

enum MissionType: String, Codable, CaseIterable, Identifiable, Sendable {
    case typing = "Typing"
    case math = "Math"
    case photo = "Photo"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .typing: return "keyboard"
        case .math: return "function"
        case .photo: return "camera.fill"
        }
    }
    
    var title: String {
        switch self {
        case .typing: return "Typing"
        case .math: return "Math"
        case .photo: return "Photo"
        }
    }
    
    var subtitle: String {
        switch self {
        case .typing: return "Type a phrase"
        case .math: return "Solve arithmetic"
        case .photo: return "Verify target scene"
        }
    }
}

enum MissionDifficulty: String, Codable, CaseIterable, Identifiable, Sendable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var id: String { rawValue }
}

@Model
final class MissionItem: Identifiable {
    @Attribute(.unique) var id: UUID
    var typeRaw: String
    var order: Int
    var difficultyRaw: String
    var configurationData: Data?
    var alarm: AlarmItem?
    
    init(
        id: UUID = UUID(),
        type: MissionType,
        order: Int = 0,
        difficulty: MissionDifficulty = .medium,
        configurationData: Data? = nil,
        alarm: AlarmItem? = nil
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.order = order
        self.difficultyRaw = difficulty.rawValue
        self.configurationData = configurationData
        self.alarm = alarm
    }
    
    var type: MissionType {
        get { MissionType(rawValue: typeRaw) ?? .math }
        set { typeRaw = newValue.rawValue }
    }
    
    var difficulty: MissionDifficulty {
        get { MissionDifficulty(rawValue: difficultyRaw) ?? .medium }
        set { difficultyRaw = newValue.rawValue }
    }
}
