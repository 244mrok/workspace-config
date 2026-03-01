import SwiftUI
import Charts

struct WeightTrendChart: View {
    let data: [(date: Date, value: Double)]
    var goalWeight: Double?

    private var yRange: ClosedRange<Double> {
        let values = data.map(\.value)
        guard let minV = values.min(), let maxV = values.max() else { return 60...80 }
        let padding = max((maxV - minV) * 0.15, 1.0)
        var lo = minV - padding
        var hi = maxV + padding
        if let goal = goalWeight {
            lo = min(lo, goal - padding)
            hi = max(hi, goal + padding)
        }
        return lo...hi
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("体重トレンド")
                .font(.headline)

            if data.isEmpty {
                ContentUnavailableView(
                    "データなし",
                    systemImage: "chart.line.downtrend.xyaxis",
                    description: Text("計測データを記録するとトレンドが表示されます")
                )
                .frame(height: 300)
            } else {
                Chart {
                    ForEach(data, id: \.date) { item in
                        LineMark(
                            x: .value("日付", item.date),
                            y: .value("体重", item.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.blue)

                        AreaMark(
                            x: .value("日付", item.date),
                            y: .value("体重", item.value)
                        )
                        .foregroundStyle(.blue.opacity(0.1))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("日付", item.date),
                            y: .value("体重", item.value)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(30)
                    }

                    if let goal = goalWeight {
                        RuleMark(y: .value("目標", goal))
                            .foregroundStyle(.green)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("目標 \(String(format: "%.1f", goal))kg")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }
                    }
                }
                .chartYScale(domain: yRange)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(String(format: "%.1f", v))
                            }
                        }
                    }
                }
                .frame(height: 300)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
