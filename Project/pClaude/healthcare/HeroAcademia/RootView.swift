import SwiftUI

struct RootView: View {
    @State private var firebaseService = FirebaseService()

    var body: some View {
        Group {
            if firebaseService.isAuthenticated {
                NavigationStack {
                    MeasurementListView(
                        viewModel: MeasurementViewModel(firebaseService: firebaseService)
                    )
                }
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
