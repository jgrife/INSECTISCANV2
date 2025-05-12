import SwiftUI
import Firebase

@main
struct insectiscanApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var tabRouter = TabRouter()
    @StateObject private var locationManager = LocationManager()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            AppEntryView()
                .environmentObject(authViewModel)
                .environmentObject(tabRouter)
                .environmentObject(locationManager)
                .environmentObject(NetworkMonitor.shared) // ✅ Use the singleton here
        }
    }
}
    