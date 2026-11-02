import SwiftUI

struct MathMissionView: View {
    let difficulty: MissionDifficulty
    let onCompleted: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var currentProblem = MathProblem(expression: "12 + 15", answer: 27)
    @State private var currentInput: String = ""
    @State private var solvedCount: Int = 0
    @State private var isErrorShaking: Bool = false
    @State private var showWrongHint: Bool = false
    @State private var didComplete: Bool = false

    private var requiredCount: Int { MathProblemGenerator.requiredCount(for: difficulty) }

    var body: some View {
        VStack(spacing: Spacing.md) {
            MissionHeader(
                title: "Solve the Problem",
                subtitle: "Problem \(min(solvedCount + 1, requiredCount)) of \(requiredCount)"
            )

            HStack(spacing: Spacing.sm) {
                ForEach(0..<requiredCount, id: \.self) { index in
                    Capsule()
                        .fill(index < solvedCount ? Color.accentColor : Color(.systemFill))
                        .frame(height: 6)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .accessibilityHidden(true)

            Spacer(minLength: 0)

            VStack(spacing: Spacing.sm + Spacing.xs) {
                Text(currentProblem.expression)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text(currentInput.isEmpty ? "?" : currentInput)
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(currentInput.isEmpty ? Color.secondary : Color.primary)
                    .frame(minWidth: 160, minHeight: 60)
                    .padding(.horizontal, Spacing.lg)
                    .background(Color(.secondarySystemBackground))
                    .continuousCorners(Radius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .stroke(showWrongHint ? Color.red : Color.clear, lineWidth: 2)
                    )
                    .offset(x: isErrorShaking && !reduceMotion ? -10 : 0)
                    .animation(isErrorShaking ? .default.repeatCount(4).speed(3) : .default, value: isErrorShaking)
                    .accessibilityLabel(currentInput.isEmpty ? "Answer, empty" : "Answer, \(currentInput)")

                Text("Not quite. Try again.")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .opacity(showWrongHint ? 1 : 0)
                    .accessibilityHidden(!showWrongHint)
            }
            .padding(.horizontal, Spacing.md)

            Spacer(minLength: 0)

            KeypadView(
                onDigitTapped: { digit in
                    showWrongHint = false
                    if currentInput.count < 6 { currentInput.append(digit) }
                },
                onDeleteTapped: {
                    showWrongHint = false
                    if !currentInput.isEmpty { currentInput.removeLast() }
                },
                onSubmitTapped: { validateAnswer() }
            )
            .padding(.bottom, Spacing.md)
        }
        .padding(.top, Spacing.md)
        .background(Color(.systemBackground))
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
            showWrongHint = true
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                isErrorShaking = false
                currentInput = ""
            }
        }
    }
}
