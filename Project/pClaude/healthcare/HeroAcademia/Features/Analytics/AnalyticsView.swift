import SwiftUI

struct AnalyticsView: View {
    @Bindable var viewModel: AnalyticsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Period selector
                Picker("期間", selection: $viewModel.selectedPeriod) {
                    ForEach(AnalyticsPeriod.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Weight trend
                WeightTrendChart(data: viewModel.weightTrendData)

                // Body fat trend
                BodyFatTrendChart(data: viewModel.bodyFatTrendData)

                // Composition breakdown
                if !viewModel.compositionBreakdown.isEmpty {
                    CompositionBreakdown(data: viewModel.compositionBreakdown)
                }

                // Correlation charts (only if data exists)
                if !viewModel.sleepWeightCorrelation.isEmpty {
                    CorrelationChart(mode: .sleepWeight, data: viewModel.sleepWeightCorrelation)
                }

                if !viewModel.stepsBodyFatCorrelation.isEmpty {
                    CorrelationChart(mode: .stepsBodyFat, data: viewModel.stepsBodyFatCorrelation)
                }

                // Heatmap
                HeatmapView(data: viewModel.heatmapData)
            }
            .padding()
        }
        .navigationTitle("分析")
        .refreshable {
            await viewModel.loadAll()
        }
        .task {
            await viewModel.loadAll()
        }
        .onChange(of: viewModel.selectedPeriod) {
            Task { await viewModel.loadAll() }
        }
    }
}
