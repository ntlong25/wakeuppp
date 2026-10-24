import Foundation
import Vision
import CoreImage
import UIKit

/// Result of analysing one camera frame for the photo mission.
struct FrameScore: Sendable {
    /// 0…1 gauge value shown in the UI.
    var gauge: Float
    var matched: Bool
    /// Mean luminance 0…1 (used for the live-feed heuristic).
    var luma: Double
}

enum FeaturePrintCodec {
    static func archive(_ observation: VNFeaturePrintObservation) -> Data? {
        try? NSKeyedArchiver.archivedData(withRootObject: observation, requiringSecureCoding: true)
    }

    static func unarchive(_ data: Data) -> VNFeaturePrintObservation? {
        try? NSKeyedUnarchiver.unarchivedObject(ofClass: VNFeaturePrintObservation.self, from: data)
    }
}

enum FrameLuma {
    /// Mean luminance from a sparse grid of a 32BGRA buffer.
    static func mean(_ buffer: CVPixelBuffer) -> Double {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return 0 }
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let stride = CVPixelBufferGetBytesPerRow(buffer)
        guard width > 0, height > 0 else { return 0 }
        let p = base.assumingMemoryBound(to: UInt8.self)
        var sum = 0.0
        var count = 0.0
        for gy in 0..<16 {
            let y = (gy * height) / 16
            for gx in 0..<16 {
                let x = (gx * width) / 16
                let o = y * stride + x * 4
                sum += 0.114 * Double(p[o]) + 0.587 * Double(p[o + 1]) + 0.299 * Double(p[o + 2])
                count += 1
            }
        }
        return sum / count / 255.0
    }
}

/// Analyses frames against a registered reference (FeaturePrint) or, without one, a generic scene classifier.
/// Used only from the camera queue.
final class PhotoFrameAnalyzer: @unchecked Sendable {
    private let reference: VNFeaturePrintObservation?
    private let maxDistance: Float
    private static let keywords = ["sink", "washbasin", "basin", "faucet", "bathroom", "toilet"]
    private static let classificationThreshold: Float = 0.70

    init(referenceData: Data?, difficulty: MissionDifficulty) {
        self.reference = referenceData.flatMap(FeaturePrintCodec.unarchive)
        self.maxDistance = PhotoThreshold.maxDistance(for: difficulty)
    }

    var usesReference: Bool { reference != nil }

    func analyze(_ buffer: CVPixelBuffer) -> FrameScore? {
        let luma = FrameLuma.mean(buffer)
        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .right, options: [:])

        if let reference {
            let request = VNGenerateImageFeaturePrintRequest()
            guard (try? handler.perform([request])) != nil,
                  let observation = request.results?.first as? VNFeaturePrintObservation else { return nil }
            var distance: Float = .greatestFiniteMagnitude
            guard (try? observation.computeDistance(&distance, to: reference)) != nil else { return nil }
            return FrameScore(
                gauge: PhotoThreshold.similarity(distance: distance, threshold: maxDistance),
                matched: distance < maxDistance,
                luma: luma
            )
        }

        let request = VNClassifyImageRequest()
        guard (try? handler.perform([request])) != nil,
              let results = request.results else { return nil }
        var best: Float = 0
        for obs in results {
            let id = obs.identifier.lowercased()
            if Self.keywords.contains(where: { id.contains($0) }) {
                best = max(best, obs.confidence)
            }
        }
        return FrameScore(gauge: best, matched: best >= Self.classificationThreshold, luma: luma)
    }
}

/// Result of a reference-registration capture.
struct CapturedReference: Sendable {
    var featurePrint: Data
    var thumbnail: Data
}

/// Grabs the next frame after `requestCapture()` and turns it into a feature print + thumbnail.
final class ReferenceCaptureAnalyzer: @unchecked Sendable {
    private let lock = NSLock()
    private var requested = false
    private let ciContext = CIContext()

    func requestCapture() {
        lock.lock(); requested = true; lock.unlock()
    }

    func analyze(_ buffer: CVPixelBuffer) -> CapturedReference? {
        lock.lock()
        let shouldCapture = requested
        if shouldCapture { requested = false }
        lock.unlock()
        guard shouldCapture else { return nil }

        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .right, options: [:])
        let request = VNGenerateImageFeaturePrintRequest()
        guard (try? handler.perform([request])) != nil,
              let observation = request.results?.first as? VNFeaturePrintObservation,
              let archived = FeaturePrintCodec.archive(observation) else { return nil }

        let image = CIImage(cvPixelBuffer: buffer).oriented(.right)
        guard let cg = ciContext.createCGImage(image, from: image.extent),
              let jpeg = UIImage(cgImage: cg).jpegData(compressionQuality: 0.6) else { return nil }
        return CapturedReference(featurePrint: archived, thumbnail: jpeg)
    }
}
