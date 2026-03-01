import SwiftUI

struct DevicePairingView: View {
    let deviceType: DeviceType
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: deviceType.iconName)
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)

                Text(deviceType.displayName)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("この機能は現在開発中です。\n今後のアップデートで対応予定です。")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("閉じる") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("デバイス接続")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
}
