import SwiftUI

struct RepeatPicker: View {
    @Binding var selectedDays: [Int] // 1: Sun, 2: Mon, ..., 7: Sat
    
    // Ordered Mon to Sun for conventional display
    private let dayOptions: [(name: String, dayIndex: Int)] = [
        ("M", 2),
        ("T", 3),
        ("W", 4),
        ("T", 5),
        ("F", 6),
        ("S", 7),
        ("S", 1)
    ]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(dayOptions, id: \.dayIndex) { item in
                let isSelected = selectedDays.contains(item.dayIndex)
                Button(action: {
                    toggleDay(item.dayIndex)
                }) {
                    Text(item.name)
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(isSelected ? Color.orange : Color.white.opacity(0.1))
                        .foregroundColor(isSelected ? .black : .white)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func toggleDay(_ day: Int) {
        if let index = selectedDays.firstIndex(of: day) {
            selectedDays.remove(at: index)
        } else {
            selectedDays.append(day)
        }
    }
}
