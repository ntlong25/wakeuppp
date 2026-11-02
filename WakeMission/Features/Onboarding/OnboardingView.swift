import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    let onFinish: () -> Void

    @State private var page = 0
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                infoPage(icon: "alarm.fill", title: "Wake Up. For Real.",
                         text: "Keep using your Clock alarms. WakeMission makes sure you're awake before they're over.")
                    .tag(0)
                infoPage(icon: "figure.walk", title: "Prove You're Up",
                         text: "After you stop an alarm, finish a typing, math, or photo mission. Until then, the alarm keeps coming back.")
                    .tag(1)
                permissionPage.tag(2)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(action: advance) {
                Text(page < 2 ? "Continue" : "Allow Access")
                    .font(.headline)
                    .foregroundStyle(Color.onAccent)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRequesting)
            .padding(Spacing.lg)
        }
        .background(Color(.systemBackground))
    }

    private func advance() {
        if page < 2 {
            withAnimation { page += 1 }
            return
        }
        isRequesting = true
        Task {
            await appState.requestAlarmAuthorization()
            _ = await CameraService.requestPermission()
            onFinish()
        }
    }

    private func infoPage(icon: String, title: String, text: String) -> some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
                .padding(.bottom, Spacing.sm)
            Text(title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text(text)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
    }

    private var permissionPage: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Spacer()
            Text("Allow Access")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity)
            permissionRow(icon: "alarm", title: "Alarms",
                          text: "Required. Rings through Silent mode and Focus until you finish.")
            permissionRow(icon: "camera", title: "Camera",
                          text: "Optional. Used only for the Photo mission. Without it, you'll get a math mission instead.")
            Spacer()
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
    }

    private func permissionRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 36)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
