import Foundation

/// Debounces per-frame vision results and applies the "feed must be live" heuristic.
struct PhotoMatchDecider: Sendable {
    let requiredConsecutive: Int
    let varianceWindow: Int
    let minLumaRange: Double

    private(set) var consecutive = 0
    private var lumas: [Double] = []

    init(requiredConsecutive: Int = 4, varianceWindow: Int = 10, minLumaRange: Double = 0.004) {
        self.requiredConsecutive = requiredConsecutive
        self.varianceWindow = varianceWindow
        self.minLumaRange = minLumaRange
    }

    var isFeedLive: Bool {
        guard lumas.count >= varianceWindow, let lo = lumas.min(), let hi = lumas.max() else { return false }
        return hi - lo >= minLumaRange
    }

    /// Returns true once enough consecutive matching frames were seen on a live feed.
    mutating func ingest(matched: Bool, luma: Double) -> Bool {
        lumas.append(luma)
        if lumas.count > varianceWindow { lumas.removeFirst(lumas.count - varianceWindow) }
        consecutive = matched ? consecutive + 1 : 0
        return consecutive >= requiredConsecutive && isFeedLive
    }

    mutating func reset() {
        consecutive = 0
        lumas.removeAll()
    }
}

enum PhotoThreshold {
    /// FeaturePrint distance below which a frame matches the reference (calibrate on device).
    static func maxDistance(for difficulty: MissionDifficulty) -> Float {
        switch difficulty {
        case .easy: return 0.55
        case .medium: return 0.45
        case .hard: return 0.35
        }
    }

    /// Maps a distance to a 0…1 "similarity" gauge value.
    static func similarity(distance: Float, threshold: Float) -> Float {
        min(max(1 - distance / (threshold * 2), 0), 1)
    }
}
