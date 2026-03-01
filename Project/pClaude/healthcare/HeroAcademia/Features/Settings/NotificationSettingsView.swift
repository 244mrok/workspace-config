import SwiftUI

struct NotificationSettingsView: View {
    @Bindable var viewModel: NotificationSettingsViewModel

    var body: some View {
        Form {
            if !viewModel.isAuthorized {
                Section {
                    Label("通知が許可されていません。設定アプリから通知を有効にしてください。", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section("計測リマインダー") {
                Toggle("毎日の計測リマインダー", isOn: $viewModel.settings.isWeighInReminderEnabled)

                if viewModel.settings.isWeighInReminderEnabled {
                    DatePicker(
                        "リマインド時刻",
                        selection: $viewModel.reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                }
            }

            Section("目標通知") {
                Toggle("マイルストーン達成通知", isOn: $viewModel.settings.isMilestoneEnabled)
                Text("目標の25%, 50%, 75%, 100%達成時に通知します")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("記録通知") {
                Toggle("連続記録達成通知", isOn: $viewModel.settings.isStreakEnabled)
                Text("7日, 14日, 30日などの連続記録達成時に通知します")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("レポート") {
                Toggle("週次レポート通知", isOn: $viewModel.settings.isWeeklyReportEnabled)
                Text("毎週日曜日に1週間のサマリーを通知します")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("通知設定")
        .task {
            await viewModel.loadSettings()
        }
        .onChange(of: viewModel.settings) {
            Task { await viewModel.saveSettings() }
        }
    }
}
