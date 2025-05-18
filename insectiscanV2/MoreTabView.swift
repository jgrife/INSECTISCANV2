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

                NavigationLink(destination: BiteJournalView()) {
                    Label("Bite Journal", systemImage: "doc.text.magnifyingglass")
                }

                NavigationLink(destination: SettingsView()) {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            .navigationTitle("More")
        }
    }
}

struct SettingsView: View {
    @AppStorage("preferredCountry") private var preferredCountry = "United States"
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false

    let countries = ["United States", "Canada", "United Kingdom", "Australia"]

    var body: some View {
        Form {
            Section(header: Text("Preferences")) {
                Picker("Preferred Country", selection: $preferredCountry) {
                    ForEach(countries, id: \ .self) { country in
                        Text(country)
                    }
                }

                Toggle("Enable Dark Mode (system setting required)", isOn: $darkModeEnabled)
            }

            Section(footer: Text("Settings are saved locally on your device.")) {
                Text("App Version 1.0.0")
            }
        }
        .navigationTitle("Settings")
    }
}
