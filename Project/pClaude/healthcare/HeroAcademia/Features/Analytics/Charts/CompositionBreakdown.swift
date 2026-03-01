import SwiftUI
import Charts

struct CompositionBreakdown: View {
    let data: [CompositionData]

    private func color(for name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "orange": return .orange
        case "gray": return .gray
        default: return .secondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("体組成")
                .font(.headline)

            if data.isEmpty {
                ContentUnavailableView(
                    "データなし",
                    systemImage: "chart.pie",
                    description: Text("体重と体脂肪率のデータがあると体組成が表示されます")
                )
                .frame(height: 250)
            } else {
                Chart(data) { item in
                    SectorMark(
                        angle: .value(item.label, item.value),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(color(for: item.color))
                    .annotation(position: .overlay) {
                        VStack(spacing: 0) {
                            Text(item.label)
                                .font(.caption2)
                                .fontWeight(.medium)
                            Text(String(format: "%.1fkg", item.value))
                                .font(.caption2)
                        }
                        .foregroundStyle(.white)
                    }
                }
                .frame(height: 250)

                // Legend
                HStack(spacing: 16) {
                    ForEach(data) { item in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(color(for: item.color))
                                .frame(width: 8, height: 8)
                            Text("\(item.label): \(String(format: "%.1f", item.value))kg")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
