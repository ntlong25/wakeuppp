import SwiftUI
import AVFoundation

struct PhotoMissionView: View {
    let difficulty: MissionDifficulty
    let onCompleted: () -> Void
    
    @StateObject private var cameraService = CameraService()
    @State private var confidence: Float = 0.0
    @State private var statusMessage: String = "Find your bathroom sink"
    @State private var steadyCounter: Int = 0
    private let requiredSteadyFrames = 4
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.orange)
                        Text("PHOTO MISSION")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                            .tracking(1.5)
                    }
                    Text("Go to your bathroom sink")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(.top, 16)
                
                // Camera Viewfinder Box
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(confidence > 0.65 ? Color.green : Color.white.opacity(0.3), lineWidth: 3)
                        )
                    
                    // Scanning reticle
                    VStack {
                        HStack {
                            CornerMarker()
                            Spacer()
                            CornerMarker()
                                .rotationEffect(.degrees(90))
                        }
                        Spacer()
                        HStack {
                            CornerMarker()
                                .rotationEffect(.degrees(270))
                            Spacer()
                            CornerMarker()
                                .rotationEffect(.degrees(180))
                        }
                    }
                    .padding(28)
                    
                    VStack(spacing: 8) {
                        Image(systemName: confidence > 0.65 ? "checkmark.circle.fill" : "viewfinder")
                            .font(.system(size: 44))
                            .foregroundColor(confidence > 0.65 ? .green : .white.opacity(0.7))
                        
                        Text(statusMessage)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 380)
                .padding(.horizontal, 24)
                
                // Confidence gauge
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recognition Confidence")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(Int(confidence * 100))%")
                            .font(.caption.bold().monospaced())
                            .foregroundColor(confidence > 0.65 ? .green : .orange)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                            Capsule()
                                .fill(confidence > 0.65 ? Color.green : Color.orange)
                                .frame(width: geo.size.width * CGFloat(min(max(confidence, 0), 1)))
                                .animation(.easeOut(duration: 0.2), value: confidence)
                        }
                    }
                    .frame(height: 10)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Help instruction
                Text("Point your camera directly at the sink and water tap.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
            }
        }
        .onAppear {
            startCamera()
        }
        .onDisappear {
            cameraService.stopSession()
        }
    }
    
    private func startCamera() {
        Task {
            let granted = await cameraService.checkPermissions()
            if granted {
                cameraService.startSession { pixelBuffer in
                    VisionVerificationService.shared.verifyFrame(pixelBuffer: pixelBuffer) { conf, isMatched, msg in
                        self.confidence = conf
                        self.statusMessage = msg
                        
                        if isMatched {
                            self.steadyCounter += 1
                            if self.steadyCounter >= self.requiredSteadyFrames {
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    onCompleted()
                                }
                            }
                        } else {
                            self.steadyCounter = 0
                        }
                    }
                }
            } else {
                statusMessage = "Camera access required to complete mission"
            }
        }
    }
}

struct CornerMarker: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 0))
        }
        .stroke(Color.orange, lineWidth: 3)
        .frame(width: 20, height: 20)
    }
}
