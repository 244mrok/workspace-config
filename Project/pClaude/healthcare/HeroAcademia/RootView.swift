import SwiftUI
import HealthKit

struct RootView: View {
    @State private var firebaseService = FirebaseService()
    @State private var healthKitService: HealthKitService? = {
        HKHealthStore.isHealthDataAvailable() ? HealthKitService() : nil
    }()

    var body: some View {
        Group {
            if firebaseService.isAuthenticated {
                MainTabView(
                    firebaseService: firebaseService,
                    healthKitService: healthKitService
                )
            } else {
                NavigationStack {
                    AuthView(
                        viewModel: AuthViewModel(firebaseService: firebaseService)
                    )
                }
            }
        }
        .animation(.default, value: firebaseService.isAuthenticated)
    }
}
