import SwiftUI

struct TypingMissionView: View {
    let difficulty: MissionDifficulty
    let onCompleted: () -> Void
    
    @State private var targetPhrase: String = ""
    @State private var userInput: String = ""
    @FocusState private var isFieldFocused: Bool
    @State private var hasSucceeded: Bool = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "keyboard.fill")
                        .foregroundColor(.orange)
                    Text("TYPING MISSION")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                        .tracking(1.5)
                }
                Text("Type the phrase accurately")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.top, 16)
            
            // Target Phrase Card
            VStack(alignment: .leading, spacing: 12) {
                Text(targetPhrase)
                    .font(.system(.title3, design: .monospaced, weight: .semibold))
                    .foregroundColor(.white)
                    .lineSpacing(6)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            }
            .padding(.horizontal)
            
            // User input area
            VStack(alignment: .leading, spacing: 8) {
                TextField("Start typing here...", text: $userInput, axis: .vertical)
                    .focused($isFieldFocused)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: userInput) { _, newValue in
                        checkCompletion(newValue)
                    }
                
                HStack {
                    Text("\(userInput.count) / \(targetPhrase.count)")
                        .font(.caption.monospaced())
                        .foregroundColor(.gray)
                    Spacer()
                    if hasSucceeded {
                        Label("Verified", systemImage: "checkmark.circle.fill")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Action Button
            Button(action: {
                if hasSucceeded {
                    onCompleted()
                }
            }) {
                HStack {
                    if hasSucceeded {
                        Image(systemName: "checkmark")
                        Text("DONE")
                    } else {
                        Text("TYPE ALL CHARACTERS")
                    }
                }
                .font(.headline.bold())
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(hasSucceeded ? Color.green : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            .disabled(!hasSucceeded)
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onAppear {
            targetPhrase = TypingPhraseGenerator.randomPhrase(for: difficulty)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { @MainActor in
                isFieldFocused = true
            }
        }
    }
    
    private func checkCompletion(_ input: String) {
        let normalizedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTarget = targetPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if normalizedInput == normalizedTarget {
            hasSucceeded = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { @MainActor in
                onCompleted()
            }
        }
    }
}
