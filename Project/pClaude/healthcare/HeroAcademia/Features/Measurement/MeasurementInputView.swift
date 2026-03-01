import SwiftUI

struct MeasurementInputView: View {
    @Bindable var viewModel: MeasurementViewModel
    var onDismiss: () -> Void
    @State private var showSaveConfirmation = false

    private enum Field: Hashable {
        case weight
        case bodyFat
    }

    @FocusState private var focusedField: Field?

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
                    TextField("体重", text: $viewModel.inputWeight, prompt: Text("0.0"))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .focused($focusedField, equals: .weight)
                        .accessibilityIdentifier("weightField")
                    Text("kg")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("体脂肪率")
                    Spacer()
                    TextField("体脂肪率", text: $viewModel.inputBodyFat, prompt: Text("0.0"))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .focused($focusedField, equals: .bodyFat)
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
                            withAnimation {
                                showSaveConfirmation = true
                            }
                            try? await Task.sleep(for: .seconds(0.8))
                            onDismiss()
                        }
                    }
                }
            }
        }
        .overlay {
            if showSaveConfirmation {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}
