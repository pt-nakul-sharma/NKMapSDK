import Foundation

public final class SDKCoordinator {

    private let apiKey: String
    private let authService: AuthenticationService
    private let configManager: ConfigurationManager
    private let networkManager: NetworkManager
    private let storageManager: LocalStorageManager
    private let stateManager: StateManager
    private let permissionManager: PermissionManager

    private var locationProvider: LocationProvider?

    public private(set) var isInitialized = false
    public private(set) var isTracking = false
    public private(set) var configuration: Configuration?

    public weak var eventDelegate: NKWalkEventDelegate?

    public init(apiKey: String) {
        self.apiKey = apiKey

        self.storageManager = LocalStorageManager()
        self.authService = AuthenticationService(storage: storageManager)
        self.configManager = ConfigurationManager(storage: storageManager)
        self.networkManager = NetworkManager()
        self.stateManager = StateManager()
        self.permissionManager = PermissionManager()
    }

    public func initialize(completion: @escaping (Result<Void, NKWalkError>) -> Void) {
        authService.authenticate(apiKey: apiKey) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.fetchConfiguration(completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func fetchConfiguration(completion: @escaping (Result<Void, NKWalkError>) -> Void) {
        configManager.fetchConfiguration(apiKey: apiKey) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let config):
                self.configuration = config
                self.setupProviders(config: config, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func setupProviders(config: Configuration, completion: @escaping (Result<Void, NKWalkError>) -> Void) {
        guard let providerConfig = config.providers.first(where: { $0.enabled }) else {
            completion(.failure(.configurationFailed(reason: "No enabled location provider found")))
            return
        }

        switch providerConfig.type {
        case .googleMaps:
            let provider = GoogleMapsProvider(config: providerConfig)
            provider.delegate = self
            self.locationProvider = provider

        case .coreLocation:
            let provider = CoreLocationProvider(config: providerConfig)
            provider.delegate = self
            self.locationProvider = provider

        case .indoorAtlas:
            completion(.failure(.configurationFailed(reason: "IndoorAtlas provider not yet implemented. Use 'google_maps' or 'core_location'.")))
            return

        case .custom:
            completion(.failure(.configurationFailed(reason: "Custom providers not yet supported")))
            return
        }

        setupNetworkSync(config: config)
        setupLifecycleObservers()

        self.isInitialized = true
        completion(.success(()))
    }

    private func setupNetworkSync(config: Configuration) {
        let eventQueue = EventQueue(storage: storageManager)
        let batchUploader = BatchUploader(
            networkManager: networkManager,
            eventQueue: eventQueue,
            config: config
        )

        stateManager.setBatchUploader(batchUploader)
        batchUploader.startPeriodicSync()
    }

    private func setupLifecycleObservers() {
        stateManager.onAppDidEnterBackground = { [weak self] in
            self?.handleBackgroundTransition()
        }

        stateManager.onAppWillEnterForeground = { [weak self] in
            self?.handleForegroundTransition()
        }

        stateManager.startObserving()
    }

    public func startTracking() throws {
        guard isInitialized else {
            throw NKWalkError.notInitialized
        }

        guard !isTracking else {
            return
        }

        permissionManager.checkLocationPermission { [weak self] status in
            guard let self = self else { return }

            switch status {
            case .authorized, .authorizedAlways, .authorizedWhenInUse:
                do {
                    try self.locationProvider?.start()
                    self.isTracking = true
                    self.eventDelegate?.nkWalk(didChangeTrackingState: true)
                } catch {
                    self.eventDelegate?.nkWalk(didFailWithError: .locationProviderError(underlying: error))
                }

            case .denied, .restricted:
                self.eventDelegate?.nkWalk(didFailWithError: .permissionDenied(permission: .location))

            case .notDetermined:
                self.permissionManager.requestLocationPermission { requestStatus in
                    if case .authorized = requestStatus {
                        try? self.startTracking()
                    } else {
                        self.eventDelegate?.nkWalk(didFailWithError: .permissionDenied(permission: .location))
                    }
                }
            }
        }
    }

    public func stopTracking() {
        guard isTracking else { return }

        locationProvider?.stop()
        isTracking = false
        eventDelegate?.nkWalk(didChangeTrackingState: false)
    }

    public func shutdown() {
        stopTracking()
        stateManager.stopObserving()
        locationProvider = nil
        isInitialized = false
    }

    private func handleBackgroundTransition() {
        guard let config = configuration else { return }

        if !config.features.backgroundLocationEnabled {
            stopTracking()
        }
    }

    private func handleForegroundTransition() {
        if isTracking {
            stateManager.batchUploader?.syncNow()
        }
    }
}

extension SDKCoordinator: LocationProviderDelegate {
    public func locationProvider(_ provider: LocationProvider, didUpdateLocation location: LocationData) {
        eventDelegate?.nkWalk(didUpdateLocation: location)

        let event = LocationEvent(location: location)
        stateManager.eventQueue?.enqueue(event)
    }

    public func locationProvider(_ provider: LocationProvider, didFailWithError error: Error) {
        eventDelegate?.nkWalk(didFailWithError: .locationProviderError(underlying: error))
    }
}
