import SwiftUI

struct MeasurementListView: View {
    @Bindable var viewModel: MeasurementViewModel
    @State private var showingAddSheet = false

    var body: some View {
        List {
            if viewModel.measurements.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    "計測データがありません",
                    systemImage: "scalemass",
                    description: Text("右上の＋ボタンから計測を記録しましょう")
                )
            }

            ForEach(viewModel.measurements) { measurement in
                MeasurementRow(measurement: measurement)
            }
            .onDelete { offsets in
                Task { await viewModel.deleteMeasurement(at: offsets) }
            }
        }
        .navigationTitle("計測記録")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                MeasurementInputView(viewModel: viewModel) {
                    showingAddSheet = false
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .task {
            viewModel.startListening()
            await viewModel.loadMeasurements()
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }
}

// MARK: - Row

private struct MeasurementRow: View {
    let measurement: BodyMeasurement

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(measurement.date.relativeString)
                    .font(.headline)
                Spacer()
                Text(measurement.source.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                if let weight = measurement.weight {
                    Label(weight.weightWithUnit, systemImage: "scalemass")
                }
                if let bodyFat = measurement.bodyFatPercentage {
                    Label(bodyFat.bodyFatWithUnit, systemImage: "percent")
                }
                if let bmi = measurement.bmi {
                    Label(bmi.bmiWithUnit, systemImage: "heart.text.square")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
