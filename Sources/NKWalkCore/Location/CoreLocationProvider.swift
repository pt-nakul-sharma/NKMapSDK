import Foundation
import CoreLocation

internal final class CoreLocationProvider: NSObject, LocationProvider {

    weak var delegate: LocationProviderDelegate?

    private(set) var status: LocationProviderStatus = .idle

    private var locationManager: CLLocationManager?
    private let config: LocationProviderConfig
    private var currentFloor: Int = 0

    init(config: LocationProviderConfig) {
        self.config = config
        super.init()
    }

    func start() throws {
        guard status != .running else { return }

        status = .starting

        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.distanceFilter = 1.0

        if #available(iOS 14.0, *) {
            switch locationManager?.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                locationManager?.startUpdatingLocation()
                status = .running
            case .notDetermined:
                throw LocationProviderError.permissionDenied
            case .denied, .restricted:
                throw LocationProviderError.permissionDenied
            default:
                throw LocationProviderError.permissionDenied
            }
        } else {
            let authStatus = CLLocationManager.authorizationStatus()
            switch authStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                locationManager?.startUpdatingLocation()
                status = .running
            default:
                throw LocationProviderError.permissionDenied
            }
        }
    }

    func stop() {
        guard status == .running else { return }

        locationManager?.stopUpdatingLocation()
        locationManager?.delegate = nil
        locationManager = nil

        status = .stopped
    }

    deinit {
        stop()
    }
}

extension CoreLocationProvider: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            let locationData = convertToLocationData(location)
            delegate?.locationProvider(self, didUpdateLocation: locationData)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        status = .error(error)
        delegate?.locationProvider(self, didFailWithError: error)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .denied || status == .restricted {
            self.status = .error(LocationProviderError.permissionDenied)
            delegate?.locationProvider(self, didFailWithError: LocationProviderError.permissionDenied)
        }
    }

    private func convertToLocationData(_ location: CLLocation) -> LocationData {
        let metadata: [String: String] = [
            "event_type": "position",
            "provider_type": "core_location"
        ]

        return LocationData(
            timestamp: location.timestamp,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            floor: location.floor?.level,
            accuracy: location.horizontalAccuracy,
            heading: location.course >= 0 ? location.course : nil,
            speed: location.speed >= 0 ? location.speed : nil,
            provider: "core_location",
            metadata: metadata
        )
    }
}
