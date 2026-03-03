import SwiftUI

struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel
    @Bindable var goalViewModel: GoalViewModel
    var watchConnectivity: WatchConnectivityService?
    @State private var showingGoalSetting = false
    @State private var showingGoalEdit = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading && viewModel.measurements.isEmpty {
                        // Shimmer loading state
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.regularMaterial)
                            .frame(height: 120)
                            .shimmer()
                    }

                    // Latest stats card
                    latestStatsCard

                    // TDEE
                    if let tdee = viewModel.estimatedTDEE {
                        tdeeCard(tdee: tdee)
                    }

                    // Goal progress — combined card
                    if !viewModel.activeGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("目標", systemImage: "target")
                                    .font(.headline)
                                Spacer()
                            }

                            if let goal = viewModel.weightGoal {
                                goalSection(for: goal)
                            }

                            if viewModel.weightGoal != nil && viewModel.bodyFatGoal != nil {
                                Divider()
                            }

                            if let goal = viewModel.bodyFatGoal {
                                goalSection(for: goal)
                            }
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    // Show add button when there's room for another goal type
                    if viewModel.activeGoals.count < GoalType.allCases.count {
                        Button {
                            goalViewModel.resetForm()
                            let existingTypes = Set(viewModel.activeGoals.map(\.type))
                            if let missingType = GoalType.allCases.first(where: { !existingTypes.contains($0) }) {
                                goalViewModel.inputType = missingType
                            }
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
                        NavigationLink {
                            BadgeListView(
                                viewModel: BadgeViewModel(
                                    firebaseService: viewModel.firebaseServiceForBadges
                                )
                            )
                        } label: {
                            streakBadge
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("ダッシュボード")
            .refreshable {
                await viewModel.loadAll()
                sendWatchData()
            }
            .task {
                await viewModel.loadAll()
                await goalViewModel.loadGoals()
                sendWatchData()
            }
            .sheet(isPresented: $showingGoalSetting) {
                GoalSettingView(viewModel: goalViewModel)
                    .onDisappear {
                        Task { await viewModel.loadAll() }
                    }
            }
            .sheet(isPresented: $showingGoalEdit) {
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
                .contentTransition(.numericText())
                .animation(.default, value: value)
            Text(unit.isEmpty ? title : "\(title)(\(unit))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func tdeeCard(tdee: Double) -> some View {
        HStack {
            Image(systemName: "flame")
                .font(.title3)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("推定消費カロリー")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(Int(tdee)) kcal/日")
                    .font(.title3.bold())
            }
            Spacer()
            Text("活動量: 軽め")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func goalSection(for goal: Goal) -> some View {
        let currentValue = viewModel.currentGoalValue(for: goal)
        let progress: Double = {
            guard let currentValue else { return 0 }
            return goal.progressPercentage(currentValue: currentValue) / 100
        }()
        let projected = viewModel.projectedDate(for: goal)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.type.displayName)
                    .font(.subheadline.bold())
                Spacer()
                Text("残り\(goal.daysRemaining)日")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let currentValue {
                Text(String(format: "%.1f → %.1f %@", currentValue, goal.targetValue, goal.type.unit))
                    .font(.subheadline)
            }

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

            if let projected {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text("達成予測: ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(projected, style: .date)
                        .font(.caption.bold())
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            goalViewModel.startEditing(goal)
            showingGoalEdit = true
        }
    }

    private var streakBadge: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
                .symbolEffect(.bounce, value: viewModel.streak)
            Text("\(viewModel.streak)日連続記録中")
                .font(.subheadline.bold())
                .contentTransition(.numericText())
            Spacer()
        }
        .padding()
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Watch Data

    private func sendWatchData() {
        guard let watchConnectivity else { return }
        let data = WatchData(
            latestWeight: viewModel.latestWeight,
            latestBodyFat: viewModel.latestBodyFat,
            goalProgress: viewModel.goalProgress,
            goalTargetValue: viewModel.activeGoal?.targetValue,
            goalType: viewModel.activeGoal?.type.rawValue,
            goalDaysRemaining: viewModel.activeGoal?.daysRemaining,
            streak: viewModel.streak
        )
        watchConnectivity.sendWatchData(data)
    }
}
