import Foundation
import AVFoundation

/// Back-camera frame source. Frames are analysed synchronously on the camera queue by a caller-supplied
/// closure; only the (Sendable) analysis result is delivered to the main actor.
final class CameraService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.wakemission.camera")
    private var handler: (@Sendable (CVPixelBuffer) -> Void)?
    private var configured = false
    private var lastFrameTime: CFTimeInterval = 0
    /// Minimum seconds between analysed frames (≈5 fps).
    private let minFrameInterval: CFTimeInterval = 0.2

    static func requestPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
        default: return false
        }
    }

    static var isDenied: Bool {
        let s = AVCaptureDevice.authorizationStatus(for: .video)
        return s == .denied || s == .restricted
    }

    func start<Output: Sendable>(
        analyze: @escaping @Sendable (CVPixelBuffer) -> Output?,
        onOutput: @escaping @Sendable @MainActor (Output) -> Void
    ) {
        sessionQueue.async { [self] in
            handler = { buffer in
                if let output = analyze(buffer) {
                    Task { @MainActor in onOutput(output) }
                }
            }
            configureIfNeeded()
            if !captureSession.isRunning { captureSession.startRunning() }
        }
    }

    func stop() {
        sessionQueue.async { [self] in
            handler = nil
            if captureSession.isRunning { captureSession.stopRunning() }
        }
    }

    private func configureIfNeeded() {
        guard !configured else { return }
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .vga640x480
        defer { captureSession.commitConfiguration() }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else { return }
        captureSession.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: sessionQueue)
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            configured = true
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = CACurrentMediaTime()
        guard now - lastFrameTime >= minFrameInterval else { return }
        lastFrameTime = now
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        handler?(buffer)
    }
}
