import SwiftUI
import CoreLocation

struct HomeView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var networkMonitor: NetworkMonitor

    @State private var showEmergencyHelp = false
    @State private var showLocationAlert = false

    @State private var weatherDescription: String?
    @State private var temperature: Double?
    @State private var humidity: Double?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Home")
                    .font(.largeTitle.bold())

                Text("Welcome to InsectiScan")
                    .font(.title)
                    .foregroundColor(Color("PrimaryColor"))
                Text("Your smart outdoor safety and identification companion.")
                    .foregroundColor(.gray)

                if !networkMonitor.isConnected {
                    Text("⚠️ You're offline. Weather and scanning features may not work.")
                        .foregroundColor(.red)
                }

                // Weather Card
                VStack(alignment: .leading) {
                    Text("🌤️ Weather – \(weatherLocationLabel)")
                        .font(.headline)

                    if let temp = temperature, let desc = weatherDescription, let hum = humidity {
                        HStack {
                            Text("\(Int(temp))°F").font(.largeTitle.bold())
                            VStack(alignment: .leading) {
                                Text(desc.capitalized)
                                Text("Humidity: \(Int(hum))%")
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
                .cornerRadius(12)

                // Tools
                VStack(alignment: .leading, spacing: 12) {
                    Text("Explore Tools")
                        .font(.title2.bold())

                    LazyVGrid(columns: [GridItem(), GridItem()], spacing: 20) {
                        HomeToolButton(icon: "camera.viewfinder", title: "Scan Bites") {
                            selectedTab = 1
                        }
                        HomeToolButton(icon: "leaf", title: "Plant ID") {
                            selectedTab = 2
                        }
                        HomeToolButton(icon: "pawprint", title: "Animal ID") {
                            selectedTab = 3
                        }
                        HomeToolButton(icon: "person.crop.circle", title: "Profile") {
                            selectedTab = 4
                        }
                        HomeToolButton(icon: "exclamationmark.triangle", title: "Emergency Help", color: .red) {
                            showEmergencyHelp = true
                        }
                    }
                }

                // Tip of the Day
                VStack(alignment: .leading, spacing: 8) {
                    Text("🧠 Daily Tip")
                        .font(.headline)
                    Text("Always let someone know your hiking route and estimated return time.")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(12)

                Spacer(minLength: 40)
            }
            .padding()
        }
        .sheet(isPresented: $showEmergencyHelp) {
            EmergencyHelpView()
        }
        .onAppear {
            fetchWeatherIfPossible()
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
                        .fill(color.opacity(0.1))
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
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
}
