import SwiftUI
import FirebaseCore

@main
struct HeroAcademiaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        // Ensure Firebase is configured before any view or service is created.
        // AppDelegate.application(_:didFinishLaunchingWithOptions:) may run after
        // @State property initializers in views, so we configure here as well.
        if FirebaseApp.app() == nil,
           Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
