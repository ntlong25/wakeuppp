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
        VStack(spacing: 12) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { key in
                        Button(action: {
                            handleKey(key)
                        }) {
                            keyContent(key)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 64)
                                .background(keyBackground(key))
                                .cornerRadius(16)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func keyContent(_ key: String) -> some View {
        switch key {
        case "del":
            Image(systemName: "delete.left.fill")
                .foregroundColor(.orange)
        case "ok":
            Image(systemName: "checkmark")
                .foregroundColor(.white)
        default:
            Text(key)
        }
    }
    
    private func keyBackground(_ key: String) -> Color {
        switch key {
        case "ok":
            return Color.orange
        case "del":
            return Color.white.opacity(0.15)
        default:
            return Color.white.opacity(0.1)
        }
    }
    
    private func handleKey(_ key: String) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
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
