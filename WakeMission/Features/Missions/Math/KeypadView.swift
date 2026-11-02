import SwiftUI

struct KeypadView: View {
    let onDigitTapped: (String) -> Void
    let onDeleteTapped: () -> Void
    let onSubmitTapped: () -> Void

    private let rows = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["del", "0", "ok"]
    ]

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: Spacing.sm) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            handleKey(key)
                        } label: {
                            keyContent(key)
                                .font(.title2.weight(.medium))
                                .frame(maxWidth: .infinity, minHeight: 52, maxHeight: 64)
                                .background(keyBackground(key))
                                .continuousCorners(Radius.md)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(accessibilityName(key))
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    @ViewBuilder
    private func keyContent(_ key: String) -> some View {
        switch key {
        case "del":
            Image(systemName: "delete.left")
                .foregroundStyle(.primary)
        case "ok":
            Image(systemName: "checkmark")
                .fontWeight(.bold)
                .foregroundStyle(Color.onAccent)
        default:
            Text(key)
                .foregroundStyle(.primary)
        }
    }

    private func keyBackground(_ key: String) -> Color {
        switch key {
        case "ok": return .accentColor
        case "del": return Color(.tertiarySystemFill)
        default: return Color(.secondarySystemFill)
        }
    }

    private func accessibilityName(_ key: String) -> String {
        switch key {
        case "del": return String(localized: "Delete")
        case "ok": return String(localized: "Submit answer")
        default: return key
        }
    }

    private func handleKey(_ key: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        switch key {
        case "del":
            onDeleteTapped()
        case "ok":
            onSubmitTapped()
        default:
            onDigitTapped(key)
        }
    }
}
