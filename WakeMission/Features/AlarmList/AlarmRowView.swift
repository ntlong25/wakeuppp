import SwiftUI

struct AlarmRowView: View {
    let alarm: AlarmItem
    let onToggle: (Bool) -> Void
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(alarm.formattedTime)
                            .font(.system(size: 44, weight: .light, design: .rounded))
                            .foregroundColor(alarm.isEnabled ? .white : .gray)
                        
                        if alarm.isEnabled {
                            Text(alarm.timeRemainingText)
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Text(alarm.label.isEmpty ? "Alarm" : alarm.label)
                            .font(.subheadline)
                            .foregroundColor(alarm.isEnabled ? .white.opacity(0.85) : .gray)
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Text(alarm.repeatSummary)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    // Mission badges
                    if !alarm.missions.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(alarm.missions.sorted(by: { $0.order < $1.order })) { mission in
                                HStack(spacing: 4) {
                                    Image(systemName: mission.type.icon)
                                        .font(.caption2)
                                    Text(mission.type.title)
                                        .font(.caption2.bold())
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(alarm.isEnabled ? 0.12 : 0.05))
                                .foregroundColor(alarm.isEnabled ? .orange : .gray)
                                .cornerRadius(6)
                            }
                        }
                        .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { alarm.isEnabled },
                    set: { onToggle($0) }
                ))
                .labelsHidden()
                .tint(.orange)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
