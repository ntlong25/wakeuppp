import Foundation

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
        case .typing: return String(localized: "Typing")
        case .math: return String(localized: "Math")
        case .photo: return String(localized: "Photo")
        }
    }

    var subtitle: String {
        switch self {
        case .typing: return String(localized: "Type a phrase")
        case .math: return String(localized: "Solve arithmetic")
        case .photo: return String(localized: "Verify target scene")
        }
    }
}

enum MissionDifficulty: String, Codable, CaseIterable, Identifiable, Sendable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy: return String(localized: "Easy")
        case .medium: return String(localized: "Medium")
        case .hard: return String(localized: "Hard")
        }
    }
}

/// Stored (JSON) in `MissionDraft.configurationData` for photo missions.
struct PhotoMissionConfig: Codable, Equatable, Sendable {
    /// Secure-coded `VNFeaturePrintObservation`.
    var featurePrint: Data
    /// JPEG thumbnail of the registered scene.
    var thumbnail: Data

    func encoded() -> Data? { try? JSONEncoder().encode(self) }

    static func decode(_ data: Data?) -> PhotoMissionConfig? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(PhotoMissionConfig.self, from: data)
    }
}

/// One configured mission in the global wake-up sequence.
struct MissionDraft: Identifiable, Equatable, Codable, Sendable {
    var id = UUID()
    var type: MissionType
    var difficulty: MissionDifficulty = .medium
    var configurationData: Data?
}
