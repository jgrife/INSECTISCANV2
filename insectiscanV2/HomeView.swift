import SwiftUI
import CoreLocation
import Firebase

struct HomeView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var showEmergencyHelp = false
    @State private var showLocationAlert = false
    @State private var showBiteJournal = false
    @State private var showLogDetail: BiteLogEntry? = nil
    @State private var tipIndex = 0

    @State private var weatherDescription: String?
    @State private var temperature: Double?
    @State private var humidity: Double?

    @State private var recentEntries: [BiteLogEntry] = []

    let tips = [
        "Always let someone know your hiking route and estimated return time.",
        "Apply bug spray to socks and shoes to help prevent tick bites.",
        "Stay on marked trails to avoid hidden nests and harmful plants.",
        "Keep an antihistamine in your kit in case of allergic reactions."
    ]

    var dynamicTip: String {
        if recentEntries.count >= 3,
           recentEntries.filter({ $0.diagnosisSummary.lowercased().contains("mosquito") }).count >= 2 {
            return "You’ve had multiple mosquito bites — consider using repellent with DEET."
        } else {
            return tips[tipIndex % tips.count]
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("InsectiScan")
                            .font(.largeTitle.bold())
                            .foregroundColor(Color("PrimaryColor"))
                    }

                    if !networkMonitor.isConnected {
                        Text("⚠️ You're offline. Weather and scanning features may not work.")
                            .foregroundColor(.red)
                    }

                    // Weather Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🌤️ Weather – \(weatherLocationLabel)")
                            .font(.headline)

                        if let temp = temperature, let desc = weatherDescription, let hum = humidity {
                            HStack(spacing: 20) {
                                Text("\(Int(temp))°F")
                                    .font(.system(size: 44, weight: .bold))
                                    .foregroundColor(.primary)

                                VStack(alignment: .leading) {
                                    Text(desc.capitalized)
                                        .font(.subheadline)
                                    Text("Humidity: \(Int(hum))%")
                                        .font(.subheadline)
                                }
                            }
                        } else if locationManager.locationDenied {
                            Text("⚠️ Location access denied. Please enable it in Settings.")
                                .foregroundColor(.red)
                        } else {
                            Text("Loading weather...")
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
                    .shadow(radius: 2)

                    // Tools Grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🧰 Tools")
                            .font(.title2.bold())

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            HomeToolButton(icon: "camera.viewfinder", title: "Scan Bites") {
                                selectedTab = 1
                            }
                            HomeToolButton(icon: "leaf", title: "Plant ID") {
                                selectedTab = 2
                            }
                            HomeToolButton(icon: "pawprint", title: "Animal ID") {
                                selectedTab = 3
                            }
                            HomeToolButton(icon: "doc.text.magnifyingglass", title: "Bite Journal", color: .purple) {
                                showBiteJournal = true
                            }
                            HomeToolButton(icon: "person.crop.circle", title: "Profile") {
                                selectedTab = 4
                            }
                            HomeToolButton(icon: "gearshape", title: "Settings", color: .gray) {
                                // Placeholder for settings
                            }
                            HomeToolButton(icon: "exclamationmark.triangle", title: "Emergency Help", color: .red) {
                                showEmergencyHelp = true
                            }
                        }
                    }

                    // Tip of the Day
                    VStack(alignment: .leading, spacing: 8) {
                        Text("💡 Smart Tip")
                            .font(.headline)
                        Text(dynamicTip)
                            .foregroundColor(.secondary)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.8), value: dynamicTip)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(16)
                    .onAppear {
                        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
                            tipIndex = (tipIndex + 1) % tips.count
                        }
                    }

                    // Recent Activity
                    if !recentEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("🕒 Recent Activity")
                                .font(.headline)

                            ForEach(recentEntries.prefix(3)) { entry in
                                Button(action: {
                                    showLogDetail = entry
                                }) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(entry.diagnosisSummary)
                                            .font(.subheadline.bold())
                                        Text(entry.notes)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Divider()
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .sheet(isPresented: $showEmergencyHelp) {
                EmergencyHelpView()
            }
            .sheet(isPresented: $showBiteJournal) {
                BiteJournalView()
            }
            .sheet(item: $showLogDetail) { entry in
                VStack(spacing: 16) {
                    AsyncImage(url: URL(string: entry.imageURL)) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Color.gray.opacity(0.1)
                    }
                    .frame(height: 200)
                    .cornerRadius(12)

                    Text(entry.diagnosisSummary)
                        .font(.headline)
                    Text(entry.notes)
                        .font(.body)
                        .padding()
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding()
            }
            .onAppear {
                fetchWeatherIfPossible()
                loadRecentBiteLogs()
            }
            .onChange(of: locationManager.locality) {
                fetchWeatherIfPossible()
            }
            .onChange(of: locationManager.locationDenied) {
                showLocationAlert = locationManager.locationDenied
            }
            .alert("Location Access Denied", isPresented: $showLocationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enable location access in Settings to get weather and local data.")
            }
        }
    }

    private var weatherLocationLabel: String {
        let city = locationManager.locality ?? "Unknown"
        let region = locationManager.administrativeArea.map { ", \($0)" } ?? ""
        return city + region
    }

    private func fetchWeatherIfPossible() {
        guard networkMonitor.isConnected else {
            print("❌ No internet — skipping weather fetch.")
            return
        }

        if let city = locationManager.locality,
           !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            WeatherService.shared.fetchWeather(forCity: city) {
                handleWeatherResponse($0)
            }
        } else if let coords = locationManager.location?.coordinate {
            WeatherService.shared.fetchWeather(forLatitude: coords.latitude, longitude: coords.longitude) {
                handleWeatherResponse($0)
            }
        } else {
            print("❌ No valid location available for weather.")
        }
    }

    private func handleWeatherResponse(_ result: Result<WeatherResponse, Error>) {
        DispatchQueue.main.async {
            switch result {
            case .success(let weather):
                self.weatherDescription = weather.weather.first?.description ?? "Unknown"
                self.temperature = weather.main.temp
                self.humidity = weather.main.humidity
            case .failure(let error):
                print("❌ Weather fetch failed: \(error)")
                self.weatherDescription = "Error: \(error.localizedDescription)"
            }
        }
    }

    private func loadRecentBiteLogs() {
        guard let uid = authViewModel.currentUser?.id else { return }
        Firestore.firestore().collection("users").document(uid).collection("biteLogs")
            .order(by: "date", descending: true).limit(to: 5).getDocuments { snapshot, _ in
                if let documents = snapshot?.documents {
                    self.recentEntries = documents.compactMap { try? $0.data(as: BiteLogEntry.self) }
                }
            }
    }
}

struct HomeToolButton: View {
    let icon: String
    let title: String
    var color: Color = .blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 60, height: 60)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 24))
                }
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
        }
    }
}
