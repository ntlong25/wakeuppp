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

    private var styledTarget: AttributedString {
        var text = AttributedString(targetPhrase)
        let n = min(correctPrefix, targetPhrase.count)
        let split = text.index(text.startIndex, offsetByCharacters: n)
        text[text.startIndex..<split].foregroundColor = .green
        text[split..<text.endIndex].foregroundColor = Color.secondary
        return text
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "keyboard.fill").foregroundStyle(.orange)
                    Text("TYPING MISSION")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                        .tracking(1.5)
                }
                Text("Type the phrase")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .padding(.top, 16)

            Text(styledTarget)
                .font(.system(.title3, design: .monospaced, weight: .semibold))
                .lineSpacing(6)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                TextField("Start typing here...", text: $userInput, axis: .vertical)
                    .focused($isFieldFocused)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(hasMismatch ? Color.red : Color.clear, lineWidth: 2)
                    )
                    .foregroundStyle(.primary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .disabled(hasSucceeded)
                    .onChange(of: userInput) { old, new in
                        handleChange(old: old, new: new)
                    }

                HStack {
                    Text("\(correctPrefix) / \(TypingValidator.normalize(targetPhrase).count)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    Spacer()
                    if hasSucceeded {
                        Label("Verified", systemImage: "checkmark.circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal)

            Spacer()
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
