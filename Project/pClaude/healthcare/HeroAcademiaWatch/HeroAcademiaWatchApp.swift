import SwiftUI

@main
struct HeroAcademiaWatchApp: App {
    @State private var sessionService = WatchSessionService()

    var body: some Scene {
        WindowGroup {
            WatchDashboardView(
                viewModel: WatchViewModel(sessionService: sessionService)
            )
            .onAppear {
                sessionService.activate()
            }
        }
    }
}
