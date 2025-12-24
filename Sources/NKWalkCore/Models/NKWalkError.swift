import Foundation

public enum NKWalkError: Error, LocalizedError {
    case invalidAPIKey
    case authenticationFailed(reason: String)
    case configurationFailed(reason: String)
    case networkError(underlying: Error)
    case locationProviderError(underlying: Error)
    case permissionDenied(permission: Permission)
    case notInitialized
    case alreadyInitialized
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "The provided API key is invalid or malformed."
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .configurationFailed(let reason):
            return "Failed to fetch configuration: \(reason)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .locationProviderError(let error):
            return "Location provider error: \(error.localizedDescription)"
        case .permissionDenied(let permission):
            return "Permission denied: \(permission.rawValue)"
        case .notInitialized:
            return "NKWalk SDK is not initialized. Call NKWalk.initialize() first."
        case .alreadyInitialized:
            return "NKWalk SDK is already initialized."
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

public enum Permission: String {
    case location = "Location"
    case locationAlways = "Location Always"
    case locationWhenInUse = "Location When In Use"
    case bluetooth = "Bluetooth"
    case motion = "Motion & Fitness"
}

public protocol NKWalkEventDelegate: AnyObject {
    func nkWalk(didUpdateLocation location: LocationData)
    func nkWalk(didFailWithError error: NKWalkError)
    func nkWalk(didChangeTrackingState isTracking: Bool)
}
