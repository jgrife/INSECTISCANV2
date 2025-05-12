import SwiftUI

struct AppEntryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("didAcceptTerms") private var didAcceptTerms = false

    var body: some View {
        Group {
            if !didAcceptTerms {
                TermsAndConditionsView()
            } else if !authViewModel.isAuthenticated {
                LoginView()
            } else {
                MainTabView()
            }
        }
    }
}
