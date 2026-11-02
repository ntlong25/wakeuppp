import SwiftUI

struct TypingMissionView: View {
    let difficulty: MissionDifficulty
    let onCompleted: () -> Void

    @State private var targetPhrase: String = ""
    @State private var userInput: String = ""
    @State private var hasSucceeded: Bool = false
    @FocusState private var isFieldFocused: Bool

    private var correctPrefix: Int {
        TypingValidator.correctPrefixLength(input: userInput, target: targetPhrase)
    }

    private var hasMismatch: Bool {
        correctPrefix < TypingValidator.normalize(userInput).count
    }

    /// Typed part is full-strength, the rest is dimmed: readable in both modes without relying on green.
    private var styledTarget: AttributedString {
        var text = AttributedString(targetPhrase)
        let n = min(correctPrefix, targetPhrase.count)
        let split = text.index(text.startIndex, offsetByCharacters: n)
        text[text.startIndex..<split].foregroundColor = Color.primary
        text[split..<text.endIndex].foregroundColor = Color.secondary
        return text
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                MissionHeader(title: "Type the Phrase", subtitle: "Capitals don't matter")

                Text(styledTarget)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .lineSpacing(Spacing.xs)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .continuousCorners(Radius.md)
                    .accessibilityLabel(targetPhrase)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    TextField("Start typing", text: $userInput, axis: .vertical)
                        .focused($isFieldFocused)
                        .padding(Spacing.md)
                        .background(Color(.secondarySystemBackground))
                        .continuousCorners(Radius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                .stroke(hasMismatch ? Color.red : Color.clear, lineWidth: 2)
                        )
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .disabled(hasSucceeded)
                        .onChange(of: userInput) { old, new in
                            handleChange(old: old, new: new)
                        }

                    HStack {
                        if hasMismatch {
                            Text("Check your last few letters")
                                .foregroundStyle(.red)
                        } else if hasSucceeded {
                            Label("Done", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(correctPrefix) of \(TypingValidator.normalize(targetPhrase).count)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .font(.footnote)
                    .padding(.horizontal, Spacing.xs)
                }
            }
            .padding(Spacing.md)
        }
        .background(Color(.systemBackground))
        .onAppear {
            targetPhrase = TypingPhraseGenerator.randomPhrase(for: difficulty)
            isFieldFocused = true
        }
    }

    private func handleChange(old: String, new: String) {
        guard !hasSucceeded else { return }
        // Reject paste / autofill: a legitimate keystroke adds at most one character.
        if TypingValidator.isSuspiciousJump(old: old, new: new) {
            userInput = old
            return
        }
        if TypingValidator.isMatch(input: new, target: targetPhrase) {
            hasSucceeded = true
            isFieldFocused = false
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onCompleted()
        }
    }
}
