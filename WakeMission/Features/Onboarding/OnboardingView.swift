import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    let onFinish: () -> Void

    @State private var page = 0

    var body: some View {
        VStack {
            TabView(selection: $page) {
                infoPage(icon: "alarm.fill", title: "Wake up. For real.",
                         text: "An alarm that only stops when you're actually awake.")
                    .tag(0)
                infoPage(icon: "figure.walk", title: "Missions get you out of bed",
                         text: "Type a phrase, solve math, or walk to your sink and show it to the camera.")
                    .tag(1)
                permissionPage.tag(2)
            }
            .tabViewStyle(.page)

            Button(action: advance) {
                Text(page < 2 ? "Next" : "Allow & Start")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.orange)
                    .foregroundColor(.black)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
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
            Image(systemName: icon).font(.system(size: 80)).foregroundColor(.orange)
            Text(title).font(.largeTitle.bold()).foregroundColor(.white).multilineTextAlignment(.center)
            Text(text).font(.body).foregroundColor(.gray).multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var permissionPage: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Two permissions").font(.largeTitle.bold()).foregroundColor(.white)
            permissionRow(icon: "alarm", title: "Alarms (required)",
                          text: "Lets WakeMission ring through Silent mode and Focus.")
            permissionRow(icon: "camera", title: "Camera (optional)",
                          text: "Only for the Photo mission. Without it, a math task is used instead.")
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private func permissionRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon).font(.title2).foregroundColor(.orange).frame(width: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundColor(.white)
                Text(text).font(.subheadline).foregroundColor(.gray)
            }
            Spacer()
        }
    }
}
