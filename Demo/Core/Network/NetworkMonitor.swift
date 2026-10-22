import Network
import Foundation

// MARK: - NetworkMonitor

/// Singleton-style shared instance using dependency injection at the call site.
/// Wraps NWPathMonitor to publish real-time connectivity changes.
final class NetworkMonitor {

    // MARK: - Shared
    static let shared = NetworkMonitor()

    // MARK: - Public State
    private(set) var isConnected: Bool = false

    /// Closure fired on the main queue whenever connectivity changes.
    var onStatusChange: ((Bool) -> Void)?

    // MARK: - Private
    private let monitor = NWPathMonitor()
    private let queue   = DispatchQueue(label: "com.demo.networkmonitor", qos: .utility)

    // MARK: - Init
    private init() {}

    // MARK: - Lifecycle

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let connected = path.status == .satisfied
            self.isConnected = connected
            DispatchQueue.main.async {
                self.onStatusChange?(connected)
            }
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }
}
