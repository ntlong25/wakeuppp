import SwiftUI
import AVFoundation

@MainActor
final class PhotoMissionModel: ObservableObject {
    @Published var gauge: Float = 0
    @Published var matched = false
    @Published var status = "Starting camera..."
    @Published var showEscape = false
    @Published var completed = false

    let camera = CameraService()
    private let analyzer: PhotoFrameAnalyzer
    private var decider = PhotoMatchDecider()
    private var escapeTask: Task<Void, Never>?
    private let escapeDelay: Duration = .seconds(90)

    var onCompleted: () -> Void = {}
    var onFallback: () -> Void = {}

    var usesReference: Bool { analyzer.usesReference }

    init(difficulty: MissionDifficulty, configurationData: Data?) {
        let config = PhotoMissionConfig.decode(configurationData)
        analyzer = PhotoFrameAnalyzer(referenceData: config?.featurePrint, difficulty: difficulty)
    }

    func start() async {
        let granted = await CameraService.requestPermission()
        guard granted else {
            status = "Camera access denied - switching to a math task"
            try? await Task.sleep(for: .seconds(2))
            onFallback()
            return
        }
        status = usesReference ? "Point at your registered spot" : "Find your bathroom sink"

        let analyzer = self.analyzer
        camera.start(
            analyze: { analyzer.analyze($0) },
            onOutput: { [weak self] score in self?.handle(score) }
        )

        escapeTask?.cancel()
        escapeTask = Task { [weak self] in
            try? await Task.sleep(for: self?.escapeDelay ?? .seconds(90))
            guard !Task.isCancelled else { return }
            self?.showEscape = true
        }
    }

    func stop() {
        escapeTask?.cancel()
        camera.stop()
    }

    private func handle(_ score: FrameScore) {
        guard !completed else { return }
        gauge = score.gauge
        matched = score.matched
        let done = decider.ingest(matched: score.matched, luma: score.luma)

        if done {
            completed = true
            status = "Verified!"
            stop()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onCompleted()
        } else if score.matched && !decider.isFeedLive {
            status = "Move the camera slightly"
        } else if score.matched {
            status = "Target found! Hold steady..."
        } else {
            status = usesReference ? "Point at your registered spot" : "Searching for your bathroom sink..."
        }
    }
}

struct PhotoMissionView: View {
    let difficulty: MissionDifficulty
    let configurationData: Data?
    let onCompleted: () -> Void
    let onFallback: () -> Void

    @StateObject private var model: PhotoMissionModel

    init(difficulty: MissionDifficulty, configurationData: Data?, onCompleted: @escaping () -> Void, onFallback: @escaping () -> Void) {
        self.difficulty = difficulty
        self.configurationData = configurationData
        self.onCompleted = onCompleted
        self.onFallback = onFallback
        _model = StateObject(wrappedValue: PhotoMissionModel(difficulty: difficulty, configurationData: configurationData))
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: "camera.fill").foregroundStyle(.orange)
                    Text("PHOTO MISSION")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                        .tracking(1.5)
                }
                Text(model.usesReference ? "Go to your registered spot" : "Go to your bathroom sink")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .padding(.top, 16)

            ZStack {
                CameraPreviewView(session: model.camera.captureSession)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                RoundedRectangle(cornerRadius: 24)
                    .stroke(model.matched ? Color.green : Color(.separator), lineWidth: 3)
                VStack {
                    Spacer()
                    Text(model.status)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                        .padding(.bottom, 16)
                }
            }
            .frame(height: 380)
            .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Match")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(model.gauge * 100))%")
                        .font(.caption.bold().monospaced())
                        .foregroundStyle(model.matched ? Color.green : Color.orange)
                }
                ProgressView(value: Double(min(max(model.gauge, 0), 1)))
                    .tint(model.matched ? .green : .orange)
            }
            .padding(.horizontal, 32)

            Spacer()

            if model.showEscape {
                Button("Can't scan? Solve math instead", action: onFallback)
                    .font(.footnote.bold())
                    .foregroundStyle(.orange)
                    .padding(.bottom, 24)
            } else {
                Text("Use the live camera - photos from your library don't count.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
            }
        }
        .background(Color(.systemBackground))
        .task {
            model.onCompleted = onCompleted
            model.onFallback = onFallback
            await model.start()
        }
        .onDisappear { model.stop() }
    }
}
