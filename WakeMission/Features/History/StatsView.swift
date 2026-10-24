import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \AlarmSessionRecord.triggeredAt, order: .reverse) private var records: [AlarmSessionRecord]

    private var successDates: [Date] {
        records.filter(\.success).compactMap(\.completedAt)
    }

    private var streak: Int { StreakCalculator.currentStreak(successDates: successDates) }

    private var weekly: [(day: Date, count: Int)] {
        StreakCalculator.dailyCounts(successDates: successDates)
    }

    private var averageWakeText: String {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
        let recent = successDates.filter { $0 >= cutoff }
        guard let seconds = StreakCalculator.averageTimeOfDay(recent) else { return "--" }
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        return String(format: "%02d:%02d", h, m)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        statCard(title: "Streak", value: "\(streak)", unit: streak == 1 ? "day" : "days", icon: "flame.fill")
                        statCard(title: "Avg wake", value: averageWakeText, unit: "30 days", icon: "sunrise.fill")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Last 7 days").font(.headline).foregroundColor(.white)
                        HStack(alignment: .bottom, spacing: 10) {
                            ForEach(weekly, id: \.day) { item in
                                VStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(item.count > 0 ? Color.orange : Color.white.opacity(0.12))
                                        .frame(height: CGFloat(20 + min(item.count, 3) * 20))
                                    Text(item.day.formatted(.dateTime.weekday(.narrow)))
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 100, alignment: .bottom)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("History").font(.headline).foregroundColor(.white)
                        if records.isEmpty {
                            Text("Complete your first wake-up to see it here.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        ForEach(records.prefix(20)) { record in
                            HStack {
                                Image(systemName: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(record.success ? .green : .red)
                                Text(record.triggeredAt.formatted(date: .abbreviated, time: .shortened))
                                    .foregroundColor(.white)
                                Spacer()
                                if record.success {
                                    Text("\(Int(record.durationSeconds / 60))m \(Int(record.durationSeconds) % 60)s")
                                        .font(.caption.monospaced())
                                        .foregroundColor(.gray)
                                }
                            }
                            .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                }
                .padding()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Stats")
        }
    }

    private func statCard(title: String, value: String, unit: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon).font(.caption.bold()).foregroundColor(.orange)
            Text(value).font(.system(size: 36, weight: .bold, design: .rounded)).foregroundColor(.white)
            Text(unit).font(.caption).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}
