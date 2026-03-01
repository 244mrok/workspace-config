import SwiftUI

struct MeasurementInputView: View {
    @Bindable var viewModel: MeasurementViewModel
    var onDismiss: () -> Void

    var body: some View {
        Form {
            Section("計測日時") {
                DatePicker(
                    "日時",
                    selection: $viewModel.inputDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .environment(\.locale, Locale(identifier: "ja_JP"))
            }

            Section("体組成") {
                HStack {
                    Text("体重")
                    Spacer()
                    TextField("0.0", text: $viewModel.inputWeight)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .accessibilityIdentifier("weightField")
                    Text("kg")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("体脂肪率")
                    Spacer()
                    TextField("0.0", text: $viewModel.inputBodyFat)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .accessibilityIdentifier("bodyFatField")
                    Text("%")
                        .foregroundStyle(.secondary)
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("計測を記録")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") {
                    viewModel.resetForm()
                    onDismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    Task {
                        await viewModel.addMeasurement()
                        if viewModel.errorMessage == nil {
                            onDismiss()
                        }
                    }
                }
            }
        }
    }
}
