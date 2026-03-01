import SwiftUI
import HealthKit

struct RootView: View {
    @State private var firebaseService = FirebaseService()
    @State private var healthKitService: HealthKitService? = {
        HKHealthStore.isHealthDataAvailable() ? HealthKitService() : nil
    }()
    var watchConnectivity: WatchConnectivityService

    var body: some View {
        Group {
            if firebaseService.isAuthenticated {
                MainTabView(
                    firebaseService: firebaseService,
                    healthKitService: healthKitService,
                    watchConnectivity: watchConnectivity
                )
            } else {
                NavigationStack {
                    AuthView(
                        viewModel: AuthViewModel(firebaseService: firebaseService)
                    )
                }
            }
        }
        .animation(.spring(duration: 0.5), value: firebaseService.isAuthenticated)
    }
}
