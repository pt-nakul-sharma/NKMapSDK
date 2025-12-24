import Foundation
import CoreLocation
import CoreBluetooth

@available(iOS 14.0, *)
internal final class PermissionManager: NSObject {

    private var locationManager: CLLocationManager?
    private var bluetoothManager: CBCentralManager?

    private var locationPermissionCompletion: ((PermissionStatus) -> Void)?
    private var bluetoothPermissionCompletion: ((PermissionStatus) -> Void)?

    override init() {
        super.init()
    }

    func checkLocationPermission(completion: @escaping (PermissionStatus) -> Void) {
        let status = CLLocationManager.authorizationStatus()
        completion(mapLocationStatus(status))
    }

    func requestLocationPermission(completion: @escaping (PermissionStatus) -> Void) {
        locationPermissionCompletion = completion

        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
        }

        let currentStatus = CLLocationManager.authorizationStatus()

        switch currentStatus {
        case .notDetermined:
            locationManager?.requestWhenInUseAuthorization()

        case .denied, .restricted:
            completion(mapLocationStatus(currentStatus))
            locationPermissionCompletion = nil

        case .authorizedAlways, .authorizedWhenInUse:
            completion(mapLocationStatus(currentStatus))
            locationPermissionCompletion = nil

        @unknown default:
            completion(.notDetermined)
            locationPermissionCompletion = nil
        }
    }

    func requestAlwaysAuthorization(completion: @escaping (PermissionStatus) -> Void) {
        locationPermissionCompletion = completion

        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
        }

        let currentStatus = CLLocationManager.authorizationStatus()

        switch currentStatus {
        case .notDetermined:
            locationManager?.requestWhenInUseAuthorization()

        case .authorizedWhenInUse:
            locationManager?.requestAlwaysAuthorization()

        case .denied, .restricted:
            completion(mapLocationStatus(currentStatus))
            locationPermissionCompletion = nil

        case .authorizedAlways:
            completion(.authorizedAlways)
            locationPermissionCompletion = nil

        @unknown default:
            completion(.notDetermined)
            locationPermissionCompletion = nil
        }
    }

    func checkBluetoothPermission(completion: @escaping (PermissionStatus) -> Void) {
        bluetoothPermissionCompletion = completion

        if bluetoothManager == nil {
            bluetoothManager = CBCentralManager(delegate: self, queue: nil)
        } else {
            let status = mapBluetoothStatus(bluetoothManager!.state)
            completion(status)
            bluetoothPermissionCompletion = nil
        }
    }

    func isLocationAuthorized() -> Bool {
        let status = CLLocationManager.authorizationStatus()
        return status == .authorizedAlways || status == .authorizedWhenInUse
    }

    func isAlwaysAuthorized() -> Bool {
        return CLLocationManager.authorizationStatus() == .authorizedAlways
    }

    private func mapLocationStatus(_ status: CLAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorizedAlways:
            return .authorizedAlways
        case .authorizedWhenInUse:
            return .authorizedWhenInUse
        @unknown default:
            return .notDetermined
        }
    }

    private func mapBluetoothStatus(_ state: CBManagerState) -> PermissionStatus {
        switch state {
        case .poweredOn:
            return .authorized
        case .poweredOff, .resetting:
            return .denied
        case .unauthorized:
            return .denied
        case .unsupported:
            return .restricted
        case .unknown:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }
}

extension PermissionManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let completion = locationPermissionCompletion else { return }

        let status = manager.authorizationStatus
        completion(mapLocationStatus(status))
        locationPermissionCompletion = nil
    }
}

extension PermissionManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard let completion = bluetoothPermissionCompletion else { return }

        let status = mapBluetoothStatus(central.state)
        completion(status)
        bluetoothPermissionCompletion = nil
    }
}
