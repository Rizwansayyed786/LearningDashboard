import Foundation
import Network

/// Observes real network reachability (NWPathMonitor). The mock API consults it so that
/// turning off Wi-Fi behaves exactly like a failing remote call would.
/// `setSimulatedOffline` is a debug helper for demos on the simulator.
final class ConnectivityMonitor: @unchecked Sendable {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ConnectivityMonitor")
    private let lock = NSLock()
    private var pathIsSatisfied = true
    private var simulatedOffline = false

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.update { $0.pathIsSatisfied = (path.status == .satisfied) }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }

    var isOnline: Bool {
        lock.lock()
        defer { lock.unlock() }
        return pathIsSatisfied && !simulatedOffline
    }

    func setSimulatedOffline(_ value: Bool) {
        update { $0.simulatedOffline = value }
    }

    private func update(_ change: (ConnectivityMonitor) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        change(self)
    }
}
