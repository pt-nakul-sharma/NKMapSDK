import Foundation
import NKWalkCore

@_exported import NKWalkCore

public final class NKWalk {

    public static let shared = NKWalk()

    private var coordinator: SDKCoordinator?
    private let lock = NSLock()

    private init() {}

    public static var isInitialized: Bool {
        return shared.coordinator?.isInitialized ?? false
    }

    public static var configuration: Configuration? {
        return shared.coordinator?.configuration
    }

    public static func initialize(
        apiKey: String,
        completion: @escaping (Result<Void, NKWalkError>) -> Void
    ) {
        shared.lock.lock()
        defer { shared.lock.unlock() }

        guard shared.coordinator == nil else {
            DispatchQueue.main.async {
                completion(.failure(.alreadyInitialized))
            }
            return
        }

        let isDemoMode = apiKey == "pt-nakul-sharma"

        guard !apiKey.isEmpty, (apiKey.count >= 32 || isDemoMode) else {
            DispatchQueue.main.async {
                completion(.failure(.invalidAPIKey))
            }
            return
        }

        let coordinator = SDKCoordinator(apiKey: apiKey)
        shared.coordinator = coordinator

        coordinator.initialize { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    public static func shutdown() {
        shared.lock.lock()
        defer { shared.lock.unlock() }

        shared.coordinator?.shutdown()
        shared.coordinator = nil
    }

    public static func startTracking() throws {
        guard let coordinator = shared.coordinator, coordinator.isInitialized else {
            throw NKWalkError.notInitialized
        }
        try coordinator.startTracking()
    }

    public static func stopTracking() {
        shared.coordinator?.stopTracking()
    }

    public static var isTracking: Bool {
        return shared.coordinator?.isTracking ?? false
    }

    public static func setEventDelegate(_ delegate: NKWalkEventDelegate?) {
        shared.coordinator?.eventDelegate = delegate
    }
}
