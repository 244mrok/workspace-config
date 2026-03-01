import SwiftUI

struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel
    @Bindable var goalViewModel: GoalViewModel
    @State private var showingGoalSetting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Latest stats card
                    latestStatsCard

                    // Goal progress
                    if let goal = viewModel.activeGoal {
                        GoalProgressCard(
                            goal: goal,
                            currentValue: viewModel.currentGoalValue,
                            projectedDate: viewModel.projectedDate,
                            onDeactivate: {
                                Task {
                                    await goalViewModel.deactivateGoal(goal)
                                    await viewModel.loadAll()
                                }
                            }
                        )
                    } else {
                        Button {
                            showingGoalSetting = true
                        } label: {
                            Label("目標を設定する", systemImage: "plus.circle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    // Trend chart
                    WeightTrendMiniChart(measurements: viewModel.measurements)

                    // Streak
                    if viewModel.streak > 0 {
                        streakBadge
                    }
                }
                .padding()
            }
            .navigationTitle("ダッシュボード")
            .refreshable {
                await viewModel.loadAll()
            }
            .task {
                await viewModel.loadAll()
                await goalViewModel.loadGoals()
            }
            .sheet(isPresented: $showingGoalSetting) {
                GoalSettingView(viewModel: goalViewModel)
                    .onDisappear {
                        Task { await viewModel.loadAll() }
                    }
            }
        }
    }

    // MARK: - Subviews

    private var latestStatsCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("最新の記録")
                    .font(.headline)
                Spacer()
                if let measurement = viewModel.latestMeasurement {
                    Text(measurement.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 24) {
                statItem(
                    title: "体重",
                    value: viewModel.latestWeight.map { String(format: "%.1f", $0) },
                    unit: "kg",
                    icon: "scalemass"
                )

                statItem(
                    title: "体脂肪率",
                    value: viewModel.latestBodyFat.map { String(format: "%.1f", $0) },
                    unit: "%",
                    icon: "percent"
                )

                statItem(
                    title: "BMI",
                    value: viewModel.calculatedBMI.map { String(format: "%.1f", $0) },
                    unit: "",
                    icon: "figure.stand"
                )
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func statItem(title: String, value: String?, unit: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
            Text(value ?? "--")
                .font(.title2.bold())
            Text(unit.isEmpty ? title : "\(title)(\(unit))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var streakBadge: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
            Text("\(viewModel.streak)日連続記録中")
                .font(.subheadline.bold())
            Spacer()
        }
        .padding()
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}
