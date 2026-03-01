import SwiftUI

struct HeatmapView: View {
    let data: [HeatmapEntry]
    let weeks: Int

    init(data: [HeatmapEntry], weeks: Int = 12) {
        self.data = data
        self.weeks = weeks
    }

    private let dayLabels = ["日", "月", "火", "水", "木", "金", "土"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    private var calendarDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let totalDays = weeks * 7

        // Find the most recent Sunday
        let weekday = calendar.component(.weekday, from: today)
        let daysToEndOfWeek = 7 - weekday
        let endDate = calendar.date(byAdding: .day, value: daysToEndOfWeek, to: today)!
        let startDate = calendar.date(byAdding: .day, value: -(totalDays - 1), to: endDate)!

        return (0..<totalDays).map { offset in
            calendar.date(byAdding: .day, value: offset, to: startDate)!
        }
    }

    private var countMap: [Date: Int] {
        let calendar = Calendar.current
        var map: [Date: Int] = [:]
        for entry in data {
            let day = calendar.startOfDay(for: entry.date)
            map[day] = entry.count
        }
        return map
    }

    private func intensity(for count: Int) -> Double {
        switch count {
        case 0: return 0
        case 1: return 0.3
        case 2: return 0.6
        default: return 1.0
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("計測ヒートマップ")
                .font(.headline)

            // Day-of-week header
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(dayLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Heatmap grid
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let days = calendarDays
            let counts = countMap

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(days, id: \.self) { day in
                    let count = counts[day] ?? 0
                    let isToday = day == today
                    let isFuture = day > today

                    RoundedRectangle(cornerRadius: 2)
                        .fill(isFuture ? Color.clear : Color.green.opacity(intensity(for: count)))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            if isToday {
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.primary, lineWidth: 1)
                            }
                        }
                }
            }

            // Legend
            HStack(spacing: 4) {
                Text("少ない")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach([0.0, 0.3, 0.6, 1.0], id: \.self) { opacity in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.green.opacity(opacity))
                        .frame(width: 12, height: 12)
                }
                Text("多い")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
