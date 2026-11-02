import SwiftUI
import AVFoundation

@MainActor
final class PhotoMissionModel: ObservableObject {
    @Published var gauge: Float = 0
    @Published var matched = false
    @Published var status = String(localized: "Starting camera...")
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
            status = String(localized: "Camera access denied - switching to a math task")
            try? await Task.sleep(for: .seconds(2))
            onFallback()
            return
        }
        status = usesReference ? String(localized: "Point at your registered spot") : String(localized: "Find your bathroom sink")

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
            status = String(localized: "Verified!")
            stop()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onCompleted()
        } else if score.matched && !decider.isFeedLive {
            status = String(localized: "Move the camera slightly")
        } else if score.matched {
            status = String(localized: "Target found! Hold steady...")
        } else {
            status = usesReference ? String(localized: "Point at your registered spot") : String(localized: "Searching for your bathroom sink...")
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
        VStack(spacing: Spacing.md) {
            MissionHeader(
                title: model.usesReference ? "Go to Your Spot" : "Go to Your Sink",
                subtitle: "Point the camera at it and hold steady"
            )

            ZStack(alignment: .bottom) {
                Color(.secondarySystemBackground)
                CameraPreviewView(session: model.camera.captureSession)
                    .accessibilityHidden(true)
                Text(model.status)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.sm + Spacing.xs)
                    .padding(.vertical, Spacing.sm)
                    .background(.black.opacity(0.6), in: Capsule())
                    .padding(.bottom, Spacing.md)
            }
            .continuousCorners(Radius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .stroke(model.matched ? Color.green : Color.clear, lineWidth: 3)
            )
            .frame(maxHeight: .infinity)

            ProgressView(value: Double(min(max(model.gauge, 0), 1))) {
                Text("Match")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .accessibilityValue("\(Int(model.gauge * 100)) percent")

            if model.showEscape {
                Button("Can't Scan? Solve Math Instead", action: onFallback)
                    .buttonStyle(.bordered)
                    .frame(minHeight: 44)
            } else {
                Text("Live camera only. Saved photos don't count.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 44)
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .task {
            model.onCompleted = onCompleted
            model.onFallback = onFallback
            await model.start()
        }
        .onDisappear { model.stop() }
    }
}
