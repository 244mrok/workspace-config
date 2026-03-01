import SwiftUI
import Charts

enum CorrelationMode {
    case sleepWeight
    case stepsBodyFat

    var title: String {
        switch self {
        case .sleepWeight: return "睡眠時間 vs 体重"
        case .stepsBodyFat: return "歩数 vs 体脂肪率"
        }
    }

    var xLabel: String {
        switch self {
        case .sleepWeight: return "睡眠時間 (h)"
        case .stepsBodyFat: return "歩数"
        }
    }

    var yLabel: String {
        switch self {
        case .sleepWeight: return "体重 (kg)"
        case .stepsBodyFat: return "体脂肪率 (%)"
        }
    }

    var pointColor: Color {
        switch self {
        case .sleepWeight: return .purple
        case .stepsBodyFat: return .teal
        }
    }
}

struct CorrelationChart: View {
    let mode: CorrelationMode
    let data: [CorrelationPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(mode.title)
                .font(.headline)

            if data.isEmpty {
                ContentUnavailableView(
                    "データ不足",
                    systemImage: "chart.dots.scatter",
                    description: Text("相関分析にはHealthKitデータと計測データの両方が必要です")
                )
                .frame(height: 250)
            } else {
                Chart(data) { point in
                    PointMark(
                        x: .value(mode.xLabel, point.xValue),
                        y: .value(mode.yLabel, point.yValue)
                    )
                    .foregroundStyle(mode.pointColor)
                    .symbolSize(50)
                }
                .chartXAxisLabel(mode.xLabel)
                .chartYAxisLabel(mode.yLabel)
                .frame(height: 250)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
