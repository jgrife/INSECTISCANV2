import Foundation
import Network
import Combine

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor() // ✅ Singleton

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published var isConnected: Bool = true

    private init() { // ✅ Private to enforce singleton use
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                print(self?.isConnected == true ? "📡 Connected to internet" : "❌ No internet connection")
            }
        }
        monitor.start(queue: queue)
    }
}
