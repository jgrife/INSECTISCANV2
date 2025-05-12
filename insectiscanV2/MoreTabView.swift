import SwiftUI

struct MoreTabView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: OutdoorSafetyView()) {
                    Label("Safety", systemImage: "cross.case")
                }

                NavigationLink(destination: ProfileView()) {
                    Label("Profile", systemImage: "person.crop.circle")
                }

                NavigationLink(destination: EmergencyHelpView()) {
                    Label("Emergency Help", systemImage: "exclamationmark.triangle.fill")
                }
            }
            .navigationTitle("More")
        }
    }
}
