import SwiftUI

/// Explains the one-time Shortcuts automation that connects Clock alarms to WakeMission.
struct ShortcutsGuideView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @AppStorage("clockSetupDone") private var clockSetupDone = false

    private let steps: [String] = [
        "Open Shortcuts, go to Automation, and tap New Automation.",
        "Choose Alarm, then Is Stopped. Turn on Is Snoozed too if you use snooze.",
        "Pick Any Alarm, or only the alarms you want missions for.",
        "Choose Run Immediately so it works while your iPhone is locked.",
        "Add the Start Wake-up Missions action from WakeMission, then save."
    ]

    var body: some View {
        List {
            Section {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, text in
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.sm + Spacing.xs) {
                        Text("\(index + 1)")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.onAccent)
                            .frame(width: 24, height: 24)
                            .background(Color.accentColor, in: Circle())
                            .accessibilityLabel("Step \(index + 1)")
                        Text(text)
                    }
                    .accessibilityElement(children: .combine)
                }
            } header: {
                Text("One-time setup")
            } footer: {
                Text("Keep your alarms in the Clock app. Wording may differ slightly between iOS versions.")
            }

            Section {
                Button("Open Shortcuts") {
                    if let url = URL(string: "shortcuts://") { openURL(url) }
                }
                if clockSetupDone {
                    Button("Mark as Not Set Up") { clockSetupDone = false }
                } else {
                    Button("I've Set This Up") {
                        clockSetupDone = true
                        dismiss()
                    }
                }
            } footer: {
                Text("WakeMission can't see your automations, so this only records what you tell it.")
            }
        }
        .navigationTitle("Connect to Clock")
        .navigationBarTitleDisplayMode(.inline)
    }
}
