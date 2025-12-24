import Foundation

public protocol LocationProvider: AnyObject {
    var delegate: LocationProviderDelegate? { get set }
    var status: LocationProviderStatus { get }

    func start() throws
    func stop()
}

public protocol LocationProviderDelegate: AnyObject {
    func locationProvider(_ provider: LocationProvider, didUpdateLocation location: LocationData)
    func locationProvider(_ provider: LocationProvider, didFailWithError error: Error)
}

public enum LocationProviderStatus: Equatable {
    case idle
    case starting
    case running
    case stopped
    case error(Error)

    public static func == (lhs: LocationProviderStatus, rhs: LocationProviderStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.starting, .starting),
             (.running, .running),
             (.stopped, .stopped):
            return true
        case (.error, .error):
            return true
        default:
            return false
        }
    }
}

public enum LocationProviderError: Error {
    case notConfigured
    case invalidCredentials
    case permissionDenied
    case initializationFailed(reason: String)
    case unknown(Error)
}
