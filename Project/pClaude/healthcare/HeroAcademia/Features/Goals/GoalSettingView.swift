import SwiftUI

struct GoalSettingView: View {
    @Bindable var viewModel: GoalViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("目標タイプ") {
                    Picker("タイプ", selection: $viewModel.inputType) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("目標値") {
                    HStack {
                        Text("現在値")
                        Spacer()
                        TextField("0.0", text: $viewModel.inputStartValue)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(viewModel.inputType.unit)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("目標値")
                        Spacer()
                        TextField("0.0", text: $viewModel.inputTargetValue)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(viewModel.inputType.unit)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("達成期限") {
                    DatePicker(
                        "期限",
                        selection: $viewModel.inputDeadline,
                        in: Date()...,
                        displayedComponents: .date
                    )
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("目標を設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        viewModel.resetForm()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            await viewModel.addGoal()
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}
