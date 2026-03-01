import SwiftUI

struct MainTabView: View {
    let firebaseService: FirebaseServiceProtocol
    let healthKitService: HealthKitServiceProtocol?

    var body: some View {
        TabView {
            DashboardView(
                viewModel: DashboardViewModel(firebaseService: firebaseService),
                goalViewModel: GoalViewModel(firebaseService: firebaseService)
            )
            .tabItem {
                Label("ダッシュボード", systemImage: "house")
            }

            NavigationStack {
                MeasurementListView(
                    viewModel: MeasurementViewModel(
                        firebaseService: firebaseService,
                        healthKitService: healthKitService
                    )
                )
            }
            .tabItem {
                Label("計測記録", systemImage: "list.clipboard")
            }

            NavigationStack {
                AnalyticsView(
                    viewModel: AnalyticsViewModel(
                        firebaseService: firebaseService,
                        healthKitService: healthKitService
                    )
                )
            }
            .tabItem {
                Label("分析", systemImage: "chart.xyaxis.line")
            }

            SettingsView(
                firebaseService: firebaseService,
                healthKitService: healthKitService
            )
            .tabItem {
                Label("設定", systemImage: "gearshape")
            }
        }
    }
}
