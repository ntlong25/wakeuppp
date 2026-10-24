import SwiftUI

@MainActor
final class ReferenceRegistrationModel: ObservableObject {
    @Published var captured: CapturedReference?
    @Published var permissionDenied = false

    let camera = CameraService()
    private let analyzer = ReferenceCaptureAnalyzer()

    func start() async {
        captured = nil
        guard await CameraService.requestPermission() else {
            permissionDenied = true
            return
        }
        let analyzer = self.analyzer
        camera.start(
            analyze: { analyzer.analyze($0) },
            onOutput: { [weak self] result in
                self?.captured = result
                self?.camera.stop()
            }
        )
    }

    func capture() { analyzer.requestCapture() }
    func stop() { camera.stop() }
}

/// Lets the user register the scene (e.g. their bathroom sink) the Photo mission must match.
struct ReferenceRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @StateObject private var model = ReferenceRegistrationModel()

    let onSave: (PhotoMissionConfig) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if model.permissionDenied {
                    Spacer()
                    Image(systemName: "camera.fill").font(.largeTitle).foregroundStyle(.secondary)
                    Text("Camera access is off. Enable it in Settings to register a reference photo.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                    .foregroundStyle(.orange)
                    Spacer()
                } else if let captured = model.captured, let image = UIImage(data: captured.thumbnail) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal)
                    HStack(spacing: 12) {
                        Button("Retake") { Task { await model.start() } }
                            .buttonStyle(.bordered)
                        Button("Use this photo") {
                            onSave(PhotoMissionConfig(featurePrint: captured.featurePrint, thumbnail: captured.thumbnail))
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .tint(.orange)
                    Spacer()
                } else {
                    Text("Stand where you want to be on wake-up (sink, coffee machine...) and frame it clearly. Good light helps.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    CameraPreviewView(session: model.camera.captureSession)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .frame(height: 420)
                        .padding(.horizontal)
                    Button {
                        model.capture()
                    } label: {
                        Circle().fill(Color.orange).frame(width: 72, height: 72)
                            .overlay(Circle().stroke(Color.white, lineWidth: 3).padding(-6))
                    }
                    Spacer()
                }
            }
            .padding(.top)
            .background(Color(.systemBackground))
            .navigationTitle("Reference Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .task { await model.start() }
            .onDisappear { model.stop() }
        }
        
    }
}
