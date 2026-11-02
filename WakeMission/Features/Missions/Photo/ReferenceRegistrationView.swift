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
            VStack(spacing: Spacing.lg) {
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
                    Spacer()
                } else if let captured = model.captured, let image = UIImage(data: captured.thumbnail) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .continuousCorners(Radius.lg)
                        .padding(.horizontal)
                    HStack(spacing: Spacing.sm + Spacing.xs) {
                        Button("Retake") { Task { await model.start() } }
                            .buttonStyle(.bordered)
                        Button {
                            onSave(PhotoMissionConfig(featurePrint: captured.featurePrint, thumbnail: captured.thumbnail))
                            dismiss()
                        } label: {
                            Text("Use Photo").foregroundStyle(Color.onAccent)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                } else {
                    Text("Stand where you want to end up, like your sink or coffee machine, and frame it clearly.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    CameraPreviewView(session: model.camera.captureSession)
                        .background(Color(.secondarySystemBackground))
                        .continuousCorners(Radius.lg)
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal)
                        .accessibilityHidden(true)
                    Button {
                        model.capture()
                    } label: {
                        Circle().fill(Color.accentColor).frame(width: 64, height: 64)
                            .padding(6)
                            .overlay(Circle().stroke(Color.primary, lineWidth: 3))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Take reference photo")
                    .padding(.bottom, Spacing.md)
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
