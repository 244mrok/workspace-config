import SwiftUI

struct WatchDashboardView: View {
    @Bindable var viewModel: WatchViewModel
    @State private var showingQuickLog = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if viewModel.hasData {
                        // Weight (large)
                        VStack(spacing: 2) {
                            Text(viewModel.weightDisplay)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                            Text("kg")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        // Body fat
                        HStack {
                            Image(systemName: "drop.halffull")
                                .foregroundStyle(.blue)
                            Text("\(viewModel.bodyFatDisplay)%")
                                .font(.headline)
                        }

                        // Goal progress
                        if viewModel.hasGoal {
                            Gauge(value: viewModel.goalProgress) {
                                Text(viewModel.goalTypeDisplay)
                                    .font(.caption2)
                            } currentValueLabel: {
                                Text(String(format: "%.0f%%", viewModel.goalProgress * 100))
                                    .font(.caption2)
                            }
                            .gaugeStyle(.accessoryCircular)
                            .tint(viewModel.goalProgress >= 1.0 ? .green : .blue)

                            Text("残り\(viewModel.goalDaysRemaining)日")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        // Streak
                        if viewModel.streak > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(.orange)
                                Text("\(viewModel.streak)日連続")
                                    .font(.caption)
                            }
                        }

                        // Quick log button
                        Button {
                            showingQuickLog = true
                        } label: {
                            Label("記録する", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)

                        // Last updated
                        if !viewModel.lastUpdated.isEmpty {
                            Text("更新: \(viewModel.lastUpdated)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "iphone.and.arrow.forward")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("iPhoneと同期中...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("HeroAcademia")
            .sheet(isPresented: $showingQuickLog) {
                QuickLogView(sessionService: viewModel.sessionService)
            }
        }
    }
}
