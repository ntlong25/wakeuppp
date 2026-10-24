import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    let onFinish: () -> Void

    @State private var page = 0

    var body: some View {
        VStack {
            TabView(selection: $page) {
                infoPage(icon: "alarm.fill", title: "Wake up. For real.",
                         text: "Keep using your Clock alarms. WakeMission makes sure you're actually awake before they're over.")
                    .tag(0)
                infoPage(icon: "figure.walk", title: "Missions get you out of bed",
                         text: "After you stop a Clock alarm, type a phrase, solve math, or show your sink to the camera. Until then, the alarm keeps coming back.")
                    .tag(1)
                permissionPage.tag(2)
            }
            .tabViewStyle(.page)

            Button(action: advance) {
                Text(page < 2 ? "Continue" : "Allow & Start")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(.systemBackground))
    }

    private func advance() {
        if page < 2 {
            withAnimation { page += 1 }
            return
        }
        Task {
            await appState.requestAlarmAuthorization()
            _ = await CameraService.requestPermission()
            onFinish()
        }
    }

    private func infoPage(icon: String, title: String, text: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: icon).font(.system(size: 80)).foregroundStyle(.orange)
            Text(title).font(.largeTitle.bold()).multilineTextAlignment(.center)
            Text(text).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var permissionPage: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Two permissions").font(.largeTitle.bold())
            permissionRow(icon: "alarm", title: "Alarms (required)",
                          text: "Lets WakeMission ring through Silent mode and Focus until you finish.")
            permissionRow(icon: "camera", title: "Camera (optional)",
                          text: "Only for the Photo mission. Without it, a math task is used instead.")
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private func permissionRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon).font(.title2).foregroundStyle(.orange).frame(width: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
