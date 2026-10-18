import Foundation
import AVFoundation
import CoreImage

final class CameraService: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    @Published var isRunning: Bool = false
    @Published var permissionGranted: Bool = false
    
    let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.wakemission.cameraQueue")
    private var frameHandler: ((CVPixelBuffer) -> Void)?
    
    override init() {
        super.init()
    }
    
    func checkPermissions() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        let isAuthorized: Bool
        switch status {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        default:
            isAuthorized = false
        }
        
        await MainActor.run {
            self.permissionGranted = isAuthorized
        }
        return isAuthorized
    }
    
    func startSession(onFrame: @escaping @Sendable (CVPixelBuffer) -> Void) {
        self.frameHandler = onFrame
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard !self.captureSession.isRunning else { return }
            
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .vga640x480
            
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.captureSession.canAddInput(videoInput) else {
                self.captureSession.commitConfiguration()
                return
            }
            
            self.captureSession.addInput(videoInput)
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            
            if self.captureSession.canAddOutput(videoOutput) {
                self.captureSession.addOutput(videoOutput)
            }
            
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
            
            DispatchQueue.main.async {
                self.isRunning = true
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            DispatchQueue.main.async {
                self.isRunning = false
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        frameHandler?(pixelBuffer)
    }
}
