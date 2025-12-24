# NKWalk SDK - Integration Guide

This guide provides step-by-step instructions for integrating the NKWalk SDK into your iOS application.

## Prerequisites

Before you begin:

1. iOS 14.0+ deployment target
2. IndoorAtlas account and credentials
3. NKWalk backend API key
4. Xcode 13.0+

## Step 1: Installation

### Using Swift Package Manager (Recommended)

1. Open your project in Xcode
2. Go to **File → Add Packages...**
3. Enter the repository URL: `https://github.com/your-org/NKWalk`
4. Select version: `1.0.0` or later
5. Click **Add Package**
6. Select your target and click **Add Package**

### Manual Installation

If you're developing the SDK locally:

```bash
# In your host app's Package.swift
dependencies: [
    .package(path: "../NKMapSDK")
]
```

## Step 2: Configure Info.plist

Add required permission descriptions to your app's `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to provide indoor navigation services.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location always to provide continuous indoor positioning.</string>

<key>NSBluetoothAlwaysUsageDescription</key>
<string>We use Bluetooth to improve indoor positioning accuracy.</string>

<key>NSMotionUsageDescription</key>
<string>We use motion sensors to improve positioning accuracy.</string>
```

**Important**: Customize these messages to match your app's purpose and language.

## Step 3: Enable Background Modes (Optional)

If you need background location tracking:

1. Select your target in Xcode
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **Background Modes**
5. Check **Location updates**

## Step 4: Backend Configuration

Set up your backend to provide configuration at `/api/v1/config`:

```json
{
  "api_key": "your_api_key",
  "providers": [
    {
      "type": "indoor_atlas",
      "enabled": true,
      "credentials": {
        "api_key": "YOUR_INDOORATLAS_API_KEY",
        "api_secret": "YOUR_INDOORATLAS_SECRET"
      },
      "settings": {}
    }
  ],
  "endpoints": {
    "auth_validate": "https://api.yourcompany.com/api/v1/auth/validate",
    "configuration": "https://api.yourcompany.com/api/v1/config",
    "events_batch": "https://api.yourcompany.com/api/v1/events/batch",
    "events_single": "https://api.yourcompany.com/api/v1/events/single"
  },
  "sync_settings": {
    "batch_size": 50,
    "sync_interval_seconds": 30,
    "max_retry_attempts": 3,
    "retry_backoff_multiplier": 2.0,
    "compression_enabled": true,
    "wifi_only_sync": false
  },
  "features": {
    "background_location_enabled": false,
    "bluetooth_enabled": true,
    "analytics_enabled": true,
    "debug_logging_enabled": false
  }
}
```

### Backend Endpoints

Your backend must implement:

#### 1. Authentication Validation

```
POST /api/v1/auth/validate
Headers: X-API-Key: {api_key}
Body: {
  "api_key": "string",
  "platform": "ios",
  "sdk_version": "1.0.0"
}

Response: {
  "token": "jwt_token",
  "expires_in": 3600
}
```

#### 2. Configuration Retrieval

```
GET /api/v1/config
Headers: X-API-Key: {api_key}

Response: {Configuration object as shown above}
```

#### 3. Batch Event Upload

```
POST /api/v1/events/batch
Headers:
  - Authorization: Bearer {token}
  - Content-Type: application/json
  - Content-Encoding: lzfse (if compressed)

Body: {
  "events": [LocationEvent],
  "metadata": {
    "platform": "ios",
    "sdk_version": "1.0.0",
    "app_version": "1.0.0"
  }
}

Response: {
  "success": true,
  "received_count": 50
}
```

## Step 5: Initialize the SDK

### AppDelegate Pattern

```swift
import UIKit
import NKWalk

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        initializeNKWalk()

        return true
    }

    private func initializeNKWalk() {
        let apiKey = "YOUR_API_KEY"

        NKWalk.initialize(apiKey: apiKey) { result in
            switch result {
            case .success:
                print("✅ NKWalk SDK initialized")

            case .failure(let error):
                print("❌ NKWalk initialization failed: \(error)")
            }
        }
    }
}
```

### SwiftUI Pattern

```swift
import SwiftUI
import NKWalk

@main
struct MyApp: App {

    init() {
        initializeNKWalk()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func initializeNKWalk() {
        NKWalk.initialize(apiKey: "YOUR_API_KEY") { result in
            switch result {
            case .success:
                print("✅ NKWalk SDK initialized")

            case .failure(let error):
                print("❌ Failed: \(error)")
            }
        }
    }
}
```

## Step 6: Implement Location Tracking

### UIKit Example

```swift
import UIKit
import NKWalk

class LocationTrackingViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        NKWalk.setEventDelegate(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        startTracking()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NKWalk.stopTracking()
    }

    private func startTracking() {
        guard NKWalk.isInitialized else {
            print("SDK not initialized")
            return
        }

        do {
            try NKWalk.startTracking()
            print("Tracking started")
        } catch {
            handleError(error)
        }
    }

    private func handleError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension LocationTrackingViewController: NKWalkEventDelegate {

    func nkWalk(didUpdateLocation location: LocationData) {
        print("📍 Location: \(location.latitude), \(location.longitude)")
        print("🏢 Floor: \(location.floor ?? 0)")
        print("📏 Accuracy: \(location.accuracy)m")

        // Update your UI
        updateUI(with: location)
    }

    func nkWalk(didFailWithError error: NKWalkError) {
        print("❌ Error: \(error.localizedDescription)")
    }

    func nkWalk(didChangeTrackingState isTracking: Bool) {
        print("🔄 Tracking state: \(isTracking ? "ON" : "OFF")")
    }

    private func updateUI(with location: LocationData) {
        // Update labels, map, etc.
    }
}
```

### SwiftUI Example

```swift
import SwiftUI
import NKWalk
import Combine

class LocationViewModel: ObservableObject, NKWalkEventDelegate {

    @Published var currentLocation: LocationData?
    @Published var isTracking = false
    @Published var errorMessage: String?

    init() {
        NKWalk.setEventDelegate(self)
    }

    func startTracking() {
        do {
            try NKWalk.startTracking()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopTracking() {
        NKWalk.stopTracking()
    }

    func nkWalk(didUpdateLocation location: LocationData) {
        DispatchQueue.main.async {
            self.currentLocation = location
        }
    }

    func nkWalk(didFailWithError error: NKWalkError) {
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
        }
    }

    func nkWalk(didChangeTrackingState isTracking: Bool) {
        DispatchQueue.main.async {
            self.isTracking = isTracking
        }
    }
}

struct ContentView: View {

    @StateObject private var viewModel = LocationViewModel()

    var body: some View {
        VStack(spacing: 20) {
            if let location = viewModel.currentLocation {
                LocationInfoView(location: location)
            } else {
                Text("No location data")
            }

            Button(viewModel.isTracking ? "Stop Tracking" : "Start Tracking") {
                if viewModel.isTracking {
                    viewModel.stopTracking()
                } else {
                    viewModel.startTracking()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

struct LocationInfoView: View {
    let location: LocationData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📍 Location")
                .font(.headline)

            Text("Lat: \(location.latitude, specifier: "%.6f")")
            Text("Lon: \(location.longitude, specifier: "%.6f")")
            Text("Floor: \(location.floor ?? 0)")
            Text("Accuracy: \(location.accuracy, specifier: "%.2f")m")
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}
```

## Step 7: Integrate Map View

### UIKit Map Integration

```swift
import UIKit
import NKWalk
import MapKit

class MapViewController: UIViewController {

    private var mapView: NKWalkMapView!
    private var currentFloor = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMapView()
        setupFloorControls()
    }

    private func setupMapView() {
        mapView = NKWalkMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)

        // Set initial region
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        mapView.setRegion(region, animated: false)
    }

    private func setupFloorControls() {
        let floorSegment = UISegmentedControl(items: ["Ground", "Floor 1", "Floor 2", "Floor 3"])
        floorSegment.selectedSegmentIndex = 0
        floorSegment.addTarget(self, action: #selector(floorChanged), for: .valueChanged)
        floorSegment.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(floorSegment)

        NSLayoutConstraint.activate([
            floorSegment.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            floorSegment.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func floorChanged(_ sender: UISegmentedControl) {
        currentFloor = sender.selectedSegmentIndex
        mapView.setFloor(currentFloor)
    }

    func addPOI(at coordinate: CLLocationCoordinate2D, title: String, floor: Int) {
        let annotation = NKWalkAnnotation(
            coordinate: coordinate,
            title: title,
            subtitle: "Floor \(floor)",
            floor: floor,
            color: .systemBlue
        )
        mapView.addAnnotation(annotation)
    }
}

extension MapViewController: NKWalkMapViewDelegate {

    func mapView(_ mapView: NKWalkMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        print("Tapped at: \(coordinate)")
    }

    func mapView(_ mapView: NKWalkMapView, didSelectAnnotation annotation: NKWalkAnnotation) {
        print("Selected: \(annotation.title ?? "Unknown")")

        // Show details
        let alert = UIAlertController(
            title: annotation.title,
            message: annotation.subtitle,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
```

### SwiftUI Map Integration

```swift
import SwiftUI
import NKWalk
import MapKit

struct MapViewWrapper: UIViewRepresentable {

    @Binding var floor: Int
    var onLocationTap: (CLLocationCoordinate2D) -> Void

    func makeUIView(context: Context) -> NKWalkMapView {
        let mapView = NKWalkMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }

    func updateUIView(_ mapView: NKWalkMapView, context: Context) {
        mapView.setFloor(floor)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onLocationTap: onLocationTap)
    }

    class Coordinator: NSObject, NKWalkMapViewDelegate {
        var onLocationTap: (CLLocationCoordinate2D) -> Void

        init(onLocationTap: @escaping (CLLocationCoordinate2D) -> Void) {
            self.onLocationTap = onLocationTap
        }

        func mapView(_ mapView: NKWalkMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            onLocationTap(coordinate)
        }
    }
}

struct IndoorMapView: View {

    @State private var currentFloor = 0
    @State private var selectedCoordinate: CLLocationCoordinate2D?

    var body: some View {
        ZStack(alignment: .top) {
            MapViewWrapper(floor: $currentFloor) { coordinate in
                selectedCoordinate = coordinate
            }

            Picker("Floor", selection: $currentFloor) {
                Text("Ground").tag(0)
                Text("Floor 1").tag(1)
                Text("Floor 2").tag(2)
                Text("Floor 3").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)
            .padding()
        }
    }
}
```

## Step 8: Production Checklist

Before deploying to production:

- [ ] Replace all placeholder API keys with production keys
- [ ] Test on physical devices (not just simulator)
- [ ] Verify all permission descriptions are user-friendly
- [ ] Test offline functionality
- [ ] Verify background location (if enabled)
- [ ] Test floor switching with real floor plans
- [ ] Monitor battery usage
- [ ] Test in low-signal areas
- [ ] Implement proper error handling
- [ ] Add analytics/logging for production monitoring
- [ ] Test app lifecycle (background/foreground transitions)
- [ ] Verify memory usage under extended use

## Troubleshooting

### Issue: SDK initialization fails

**Solution:**

- Verify API key is correct
- Check network connectivity
- Ensure backend endpoints are accessible
- Check Xcode console for specific error messages

### Issue: Location updates not received

**Solution:**

- Verify location permissions are granted
- Check that tracking was started (`NKWalk.startTracking()`)
- Ensure IndoorAtlas floor plans are configured
- Verify Bluetooth is enabled
- Test on physical device (not simulator)

### Issue: Map not displaying correctly

**Solution:**

- Check that map view is properly added to view hierarchy
- Verify delegate is set
- Check that annotations have correct coordinates
- Ensure floor numbers match your floor plan configuration

### Issue: Events not syncing to backend

**Solution:**

- Verify network connectivity
- Check backend endpoint URLs in configuration
- Ensure authentication token is valid
- Check backend logs for incoming requests
- Verify payload format matches expected schema

## Support Resources

- **Documentation**: [https://docs.nkwalk.com](https://docs.nkwalk.com)
- **API Reference**: [https://docs.nkwalk.com/api](https://docs.nkwalk.com/api)
- **GitHub Issues**: [https://github.com/your-org/NKWalk/issues](https://github.com/your-org/NKWalk/issues)
- **Email Support**: support@nkwalk.com
- **Slack Community**: [https://nkwalk.slack.com](https://nkwalk.slack.com)

## Next Steps

1. Review the [Architecture Documentation](ARCHITECTURE.md)
2. Explore the [Demo App](Examples/NKWalkDemo)
3. Read the [API Reference](README.md#api-reference)
4. Join our developer community for support
