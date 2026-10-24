import SwiftUI

struct MathMissionView: View {
    let difficulty: MissionDifficulty
    let onCompleted: () -> Void

    @State private var currentProblem = MathProblem(expression: "12 + 15", answer: 27)
    @State private var currentInput: String = ""
    @State private var solvedCount: Int = 0
    @State private var isErrorShaking: Bool = false
    @State private var didComplete: Bool = false

    private var requiredCount: Int { MathProblemGenerator.requiredCount(for: difficulty) }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: "function").foregroundColor(.orange)
                    Text("MATH MISSION")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                        .tracking(1.5)
                }
                Text("Solve to continue")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.top, 16)

            HStack(spacing: 8) {
                ForEach(0..<requiredCount, id: \.self) { index in
                    Capsule()
                        .fill(index < solvedCount ? Color.green : Color.white.opacity(0.2))
                        .frame(height: 6)
                }
            }
            .padding(.horizontal, 32)

            Text("Problem \(min(solvedCount + 1, requiredCount)) of \(requiredCount)")
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()

            VStack(spacing: 16) {
                Text(currentProblem.expression)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(currentInput.isEmpty ? "?" : currentInput)
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundColor(currentInput.isEmpty ? .gray : .orange)
                    .frame(minWidth: 160, minHeight: 64)
                    .padding(.horizontal, 24)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isErrorShaking ? Color.red : Color.white.opacity(0.2), lineWidth: 2)
                    )
                    .offset(x: isErrorShaking ? -10 : 0)
                    .animation(isErrorShaking ? .default.repeatCount(4).speed(3) : .default, value: isErrorShaking)
            }

            Spacer()

            KeypadView(
                onDigitTapped: { digit in
                    if currentInput.count < 6 { currentInput.append(digit) }
                },
                onDeleteTapped: {
                    if !currentInput.isEmpty { currentInput.removeLast() }
                },
                onSubmitTapped: { validateAnswer() }
            )
            .padding(.bottom, 24)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onAppear { loadNextProblem() }
    }

    private func loadNextProblem() {
        currentInput = ""
        currentProblem = MathProblemGenerator.generate(for: difficulty)
    }

    private func validateAnswer() {
        guard !didComplete, let answer = Int(currentInput) else { return }

        if answer == currentProblem.answer {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            solvedCount += 1
            if solvedCount >= requiredCount {
                didComplete = true
                onCompleted()
            } else {
                loadNextProblem()
            }
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            isErrorShaking = true
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                isErrorShaking = false
                currentInput = ""
            }
        }
    }
}
