import SwiftUI
import WidgetKit

struct WeightCircularView: View {
    let entry: WeightEntry

    var body: some View {
        Gauge(value: entry.goalProgress) {
            Image(systemName: "scalemass")
        } currentValueLabel: {
            Text(entry.weight)
                .font(.system(.body, design: .rounded))
        }
        .gaugeStyle(.accessoryCircular)
    }
}

struct WeightRectangularView: View {
    let entry: WeightEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("体重")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(entry.weight) kg")
                    .font(.headline)
            }
            Spacer()
            if entry.streak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(entry.streak)")
                }
                .font(.caption)
            }
        }
    }
}

struct WeightInlineView: View {
    let entry: WeightEntry

    var body: some View {
        Text("⚖️ \(entry.weight)kg")
    }
}
