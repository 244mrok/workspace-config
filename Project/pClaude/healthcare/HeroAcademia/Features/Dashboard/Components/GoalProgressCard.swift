import SwiftUI

struct GoalProgressCard: View {
    let goal: Goal
    let currentValue: Double?
    let projectedDate: Date?
    let onDeactivate: () -> Void

    private var progress: Double {
        guard let currentValue else { return 0 }
        return goal.progressPercentage(currentValue: currentValue) / 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("目標", systemImage: "target")
                    .font(.headline)
                Spacer()
                Text("残り\(goal.daysRemaining)日")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Goal type and values
            HStack {
                VStack(alignment: .leading) {
                    Text(goal.type.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let currentValue {
                        Text(String(format: "%.1f → %.1f %@", currentValue, goal.targetValue, goal.type.unit))
                            .font(.subheadline)
                    }
                }
                Spacer()
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: min(max(progress, 0), 1))
                    .tint(progress >= 1.0 ? .green : .blue)
                    .animation(.easeInOut(duration: 0.8), value: progress)

                Text(String(format: "%.0f%%", min(progress * 100, 100)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.default, value: progress)
            }

            // Projected date
            if let projectedDate {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text("達成予測: ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(projectedDate, style: .date)
                        .font(.caption.bold())
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
