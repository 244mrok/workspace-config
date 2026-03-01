import SwiftUI

struct GoalDetailView: View {
    let goal: Goal
    let currentValue: Double?
    let projectedDate: Date?
    let onDeactivate: () -> Void

    private var progress: Double {
        guard let currentValue else { return 0 }
        return goal.progressPercentage(currentValue: currentValue)
    }

    private var dailyPace: Double? {
        guard let currentValue else { return nil }
        return GoalEngine.requiredDailyPace(goal: goal, currentValue: currentValue)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()

    @State private var showCelebration = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label(goal.type.displayName, systemImage: goal.type == .weight ? "scalemass" : "percent")
                    .font(.headline)
                Spacer()
                Text("残り\(goal.daysRemaining)日")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: min(progress / 100, 1.0))
                    .tint(progress >= 100 ? .green : .blue)

                HStack {
                    Text(String(format: "%.1f%%", progress))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let currentValue {
                        Text("現在: \(String(format: "%.1f", currentValue))\(goal.type.unit)")
                            .font(.caption)
                    }
                    Text("目標: \(String(format: "%.1f", goal.targetValue))\(goal.type.unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Stats
            HStack(spacing: 20) {
                if let pace = dailyPace {
                    VStack {
                        Text(String(format: "%+.2f", pace))
                            .font(.title3.bold())
                        Text("\(goal.type.unit)/日")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let projectedDate {
                    VStack {
                        Text(Self.dateFormatter.string(from: projectedDate))
                            .font(.title3.bold())
                        Text("達成予測日")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Deactivate button
            Button(role: .destructive) {
                onDeactivate()
            } label: {
                Text("目標を終了する")
                    .font(.caption)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            if showCelebration {
                CelebrationView()
            }
        }
        .onAppear {
            if progress >= 100 {
                showCelebration = true
            }
        }
    }
}
