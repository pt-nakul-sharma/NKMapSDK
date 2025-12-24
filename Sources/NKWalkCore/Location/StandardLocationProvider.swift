import Foundation
import CoreLocation

internal final class StandardLocationProvider: NSObject, LocationProvider {

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

        let authStatus = locationManager?.authorizationStatus ?? .notDetermined

        switch authStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager?.startUpdatingLocation()
            status = .running
        default:
            throw LocationProviderError.permissionDenied
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

extension StandardLocationProvider: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            let floor = location.floor?.level

            var metadata: [String: String] = [
                "event_type": "position",
                "provider_type": "standard"
            ]

            if let floor = floor {
                metadata["floor_detected"] = "true"
                metadata["floor_level"] = "\(floor)"

                if floor != currentFloor {
                    currentFloor = floor
                    metadata["event_type"] = "floor_change"
                }
            }

            let locationData = LocationData(
                timestamp: location.timestamp,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                floor: floor,
                accuracy: location.horizontalAccuracy,
                heading: location.course >= 0 ? location.course : nil,
                speed: location.speed >= 0 ? location.speed : nil,
                provider: "standard",
                metadata: metadata
            )

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
}
