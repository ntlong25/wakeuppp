import Foundation
import Vision
import CoreImage

final class VisionVerificationService: @unchecked Sendable {
    static let shared = VisionVerificationService()
    
    private var isProcessing = false
    private let targetKeywords = ["sink", "washbasin", "faucet", "bathroom", "water tap", "basin"]
    private let confidenceThreshold: Float = 0.65
    
    private init() {}
    
    func verifyFrame(
        pixelBuffer: CVPixelBuffer,
        completion: @escaping @Sendable @MainActor (Float, Bool, String) -> Void
    ) {
        guard !isProcessing else { return }
        isProcessing = true
        
        let request = VNClassifyImageRequest { [weak self] request, error in
            defer { self?.isProcessing = false }
            
            guard error == nil,
                  let observations = request.results as? [VNClassificationObservation] else {
                DispatchQueue.main.async { @MainActor in
                    completion(0.0, false, "Looking for target...")
                }
                return
            }
            
            // Search for target objects
            var highestConfidence: Float = 0.0
            var matchedIdentifier: String = ""
            
            for observation in observations {
                let id = observation.identifier.lowercased()
                for keyword in self?.targetKeywords ?? [] {
                    if id.contains(keyword) {
                        if observation.confidence > highestConfidence {
                            highestConfidence = observation.confidence
                            matchedIdentifier = observation.identifier
                        }
                    }
                }
            }
            
            let isMatched = highestConfidence >= (self?.confidenceThreshold ?? 0.65)
            DispatchQueue.main.async { @MainActor in
                let statusText = isMatched ? "Target Found! Keep Steady..." : "Searching for bathroom sink..."
                completion(highestConfidence, isMatched, statusText)
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        do {
            try handler.perform([request])
        } catch {
            isProcessing = false
            DispatchQueue.main.async { @MainActor in
                completion(0.0, false, "Vision error")
            }
        }
    }
}
