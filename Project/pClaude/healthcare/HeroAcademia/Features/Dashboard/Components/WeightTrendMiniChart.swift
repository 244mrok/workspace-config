import SwiftUI
import Charts

struct WeightTrendMiniChart: View {
    let measurements: [BodyMeasurement]

    private var weightData: [(date: Date, weight: Double)] {
        measurements
            .compactMap { m in m.weight.map { (m.date, $0) } }
            .sorted { $0.date < $1.date }
    }

    private var yRange: ClosedRange<Double> {
        guard let minW = weightData.map(\.weight).min(),
              let maxW = weightData.map(\.weight).max() else {
            return 60...80
        }
        let padding = max((maxW - minW) * 0.1, 0.5)
        return (minW - padding)...(maxW + padding)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("体重トレンド")
                .font(.headline)

            if weightData.isEmpty {
                ContentUnavailableView(
                    "データなし",
                    systemImage: "chart.line.downtrend.xyaxis",
                    description: Text("計測データを記録するとトレンドが表示されます")
                )
                .frame(height: 200)
            } else {
                Chart(weightData, id: \.date) { item in
                    LineMark(
                        x: .value("日付", item.date),
                        y: .value("体重", item.weight)
                    )
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("日付", item.date),
                        y: .value("体重", item.weight)
                    )
                    .foregroundStyle(.blue.opacity(0.1))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("日付", item.date),
                        y: .value("体重", item.weight)
                    )
                    .symbolSize(20)
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
                                Text(String(format: "%.0f", v))
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
