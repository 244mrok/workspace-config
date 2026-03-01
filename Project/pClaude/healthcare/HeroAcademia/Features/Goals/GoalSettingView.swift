import SwiftUI

struct GoalSettingView: View {
    @Bindable var viewModel: GoalViewModel
    @Environment(\.dismiss) private var dismiss

    private var isEditMode: Bool { viewModel.editingGoal != nil }

    private enum Field: Hashable {
        case startValue
        case targetValue
    }

    @FocusState private var focusedField: Field?

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
                    .disabled(isEditMode)
                }

                Section("目標値") {
                    HStack {
                        Text("現在値")
                        Spacer()
                        if isEditMode {
                            Text(viewModel.inputStartValue)
                                .foregroundStyle(.secondary)
                        } else {
                            TextField("現在値", text: $viewModel.inputStartValue, prompt: Text("0.0"))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                                .focused($focusedField, equals: .startValue)
                        }
                        Text(viewModel.inputType.unit)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("目標値")
                        Spacer()
                        TextField("目標値", text: $viewModel.inputTargetValue, prompt: Text("0.0"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .focused($focusedField, equals: .targetValue)
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
            .navigationTitle(isEditMode ? "目標を編集" : "目標を設定")
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
                            if isEditMode {
                                await viewModel.updateExistingGoal()
                            } else {
                                await viewModel.addGoal()
                            }
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
