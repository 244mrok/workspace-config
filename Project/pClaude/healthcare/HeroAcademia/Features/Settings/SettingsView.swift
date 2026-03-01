import SwiftUI

struct SettingsView: View {
    let firebaseService: FirebaseServiceProtocol
    let healthKitService: HealthKitServiceProtocol?
    @State private var showingSignOutAlert = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("アカウント") {
                    if let userId = firebaseService.currentUserId {
                        LabeledContent("ユーザーID", value: String(userId.prefix(8)) + "...")
                    }
                    Button("ログアウト", role: .destructive) {
                        showingSignOutAlert = true
                    }
                }

                Section("HealthKit") {
                    if let hk = healthKitService {
                        LabeledContent("利用可能", value: hk.isAvailable ? "はい" : "いいえ")
                        LabeledContent("認証済み", value: hk.isAuthorized ? "はい" : "いいえ")
                        if !hk.isAuthorized && hk.isAvailable {
                            Button("HealthKitを連携する") {
                                Task {
                                    try? await hk.requestAuthorization()
                                }
                            }
                        }
                    } else {
                        Text("HealthKitは利用できません")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("通知設定") {
                    NavigationLink {
                        NotificationSettingsView(
                            viewModel: NotificationSettingsViewModel(
                                firebaseService: firebaseService
                            )
                        )
                    } label: {
                        Label("通知設定", systemImage: "bell")
                    }
                }

                Section("デバイス連携") {
                    NavigationLink {
                        DeviceListView(
                            viewModel: DeviceViewModel(
                                firebaseService: firebaseService
                            )
                        )
                    } label: {
                        Label("デバイス管理", systemImage: "sensor")
                    }
                }

                Section("アプリ情報") {
                    LabeledContent("バージョン", value: appVersion)
                    LabeledContent("アプリ名", value: "HeroAcademia")
                }
            }
            .navigationTitle("設定")
            .alert("ログアウト", isPresented: $showingSignOutAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("ログアウト", role: .destructive) {
                    try? firebaseService.signOut()
                }
            } message: {
                Text("ログアウトしますか？")
            }
        }
    }
}
