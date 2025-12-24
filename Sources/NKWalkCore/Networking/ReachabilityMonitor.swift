import Foundation
import Network

internal final class ReachabilityMonitor {

    private var pathMonitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "com.nkwalk.reachability")

    private(set) var isReachable = false
    private(set) var isWiFi = false
    private(set) var isCellular = false

    private var onChangeCallback: ((Bool) -> Void)?

    func startMonitoring(onChange: @escaping (Bool) -> Void) {
        stopMonitoring()

        onChangeCallback = onChange

        pathMonitor = NWPathMonitor()

        pathMonitor?.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            let wasReachable = self.isReachable

            self.isReachable = path.status == .satisfied
            self.isWiFi = path.usesInterfaceType(.wifi)
            self.isCellular = path.usesInterfaceType(.cellular)

            if wasReachable != self.isReachable {
                DispatchQueue.main.async {
                    self.onChangeCallback?(self.isReachable)
                }
            }
        }

        pathMonitor?.start(queue: monitorQueue)
    }

    func stopMonitoring() {
        pathMonitor?.cancel()
        pathMonitor = nil
        onChangeCallback = nil
    }

    deinit {
        stopMonitoring()
    }
}
