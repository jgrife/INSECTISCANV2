import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locality: String?
    @Published var administrativeArea: String?
    @Published var locationDenied: Bool = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        requestPermission()
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation() // 🔥 Trigger location prompt
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        print("🔑 Authorization changed to: \(authorizationStatus.rawValue)")

        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            locationDenied = false
        case .denied, .restricted:
            locationDenied = true
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            self.location = location
            fetchLocality(from: location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
    }

    private func fetchLocality(from location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard error == nil else {
                print("❌ Geocoding error: \(error!.localizedDescription)")
                return
            }

            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    self.locality = placemark.locality
                    self.administrativeArea = placemark.administrativeArea
                    print("📍 Resolved location: \(self.locality ?? "N/A"), \(self.administrativeArea ?? "N/A")")
                }
            }
        }
    }
}
