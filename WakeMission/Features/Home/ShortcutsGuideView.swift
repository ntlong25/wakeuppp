import SwiftUI

/// Explains the one-time Shortcuts automation that connects Clock alarms to WakeMission.
struct ShortcutsGuideView: View {
    @Environment(\.openURL) private var openURL

    private let steps: [String] = [
        "Create your alarms in the Clock app, as you always do.",
        "Open Shortcuts and go to the Automation tab, then tap New Automation.",
        "Choose Alarm, select \"Is Stopped\" (also turn on \"Is Snoozed\" if you use snooze), and pick the alarms or Any Alarm.",
        "Choose \"Run Immediately\" so it works while the phone is locked.",
        "Add the action Start Wake-up Missions from WakeMission, then save."
    ]

    var body: some View {
        List {
            Section {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, text in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.orange, in: Circle())
                        Text(text)
                    }
                    .padding(.vertical, 2)
                }
            } footer: {
                Text("Wording may differ slightly between iOS versions. After setup, stop a Clock alarm and WakeMission takes over.")
            }

            Section {
                Button("Open Shortcuts") {
                    if let url = URL(string: "shortcuts://") { openURL(url) }
                }
            }
        }
        .navigationTitle("Connect to Clock")
        .navigationBarTitleDisplayMode(.inline)
    }
}
