# NKWalk SDK - Quick Start Guide

Get your iOS app tracking indoor location in **5 minutes**.

## Prerequisites

- iOS project in Xcode
- iOS 14.0+ deployment target
- Backend with NKWalk API endpoints

## Step 1: Add SDK to Your Project

**In Xcode:**

1. **File → Add Packages...**
2. Click **"Add Local..."**
3. Navigate to SDK directory: `/path/to/NKMapSDK`
4. Click **"Add Package"**
5. Select **"NKWalk"** library

## Step 2: Configure Permissions

Add to your app's `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location for indoor navigation</string>

<key>NSMotionUsageDescription</key>
<string>We use motion sensors for better floor detection</string>
```

## Step 3: Initialize SDK

**In AppDelegate.swift:**

```swift
import NKWalk

func application(_ application: UIApplication,
                didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    NKWalk.initialize(apiKey: "YOUR_API_KEY") { result in
        switch result {
        case .success:
            print("✅ NKWalk SDK ready")
        case .failure(let error):
            print("❌ Init failed: \(error)")
        }
    }

    return true
}
```

## Step 4: Track Location

**In your ViewController:**

```swift
import NKWalk

class MyViewController: UIViewController, NKWalkEventDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set delegate
        NKWalk.setEventDelegate(self)

        // Start tracking
        try? NKWalk.startTracking()
    }

    // Receive location updates
    func nkWalk(didUpdateLocation location: LocationData) {
        print("📍 Lat: \(location.latitude), Lon: \(location.longitude)")
        print("🏢 Floor: \(location.floor ?? 0)")
        print("🎯 Accuracy: \(location.accuracy)m")
    }

    func nkWalk(didFailWithError error: NKWalkError) {
        print("❌ \(error)")
    }

    func nkWalk(didChangeTrackingState isTracking: Bool) {
        print("Tracking: \(isTracking)")
    }
}
```

## Step 5: Display Map (Optional)

```swift
import NKWalk

let mapView = NKWalkMapView(frame: view.bounds)
mapView.showsUserLocation = true
mapView.delegate = self
view.addSubview(mapView)

// Add point of interest
let poi = NKWalkAnnotation(
    coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    title: "Meeting Room A",
    floor: 2,
    color: .systemBlue
)
mapView.addAnnotation(poi)
mapView.setFloor(2)
```

## Backend Configuration

Your backend must implement these endpoints:

### 1. Authentication

```
POST /api/v1/auth/validate
Headers: X-API-Key: {your_api_key}

Response:
{
  "token": "jwt_token_here",
  "expires_in": 3600
}
```

### 2. Configuration

```
GET /api/v1/config
Headers: X-API-Key: {your_api_key}

Response:
{
  "providers": [{
    "type": "google_maps",
    "enabled": true,
    "credentials": {}
  }],
  "endpoints": {
    "auth_validate": "https://api.yourapp.com/api/v1/auth/validate",
    "configuration": "https://api.yourapp.com/api/v1/config",
    "events_batch": "https://api.yourapp.com/api/v1/events/batch",
    "events_single": "https://api.yourapp.com/api/v1/events/single"
  },
  "sync_settings": {
    "batch_size": 50,
    "sync_interval_seconds": 30
  }
}
```

### 3. Event Upload

```
POST /api/v1/events/batch
Headers: Authorization: Bearer {token}

Body:
{
  "events": [
    {
      "id": "uuid",
      "timestamp": "2024-12-24T12:00:00Z",
      "latitude": 37.7749,
      "longitude": -122.4194,
      "floor": 2,
      "accuracy": 5.0,
      "provider": "google_maps"
    }
  ],
  "metadata": {
    "platform": "ios",
    "sdk_version": "1.0.0"
  }
}

Response:
{
  "success": true,
  "events_received": 1
}
```

## Test Your Integration

1. **Build your app** (⌘B)
2. **Run on physical device** (simulator has limited location)
3. **Grant permissions** when prompted
4. **Check console** for SDK initialization
5. **Walk around** to see location updates

## What's Working

✅ SDK initializes and authenticates
✅ Location tracking starts
✅ Floor detection (in supported venues)
✅ Events queue offline, sync when online
✅ Map view displays your location

## Next Steps

- **Detailed Integration**: See `INTEGRATION_GUIDE.md`
- **API Reference**: See `README.md`
- **Architecture**: See `ARCHITECTURE.md`
- **Google Maps Setup**: See `GOOGLE_MAPS_SETUP.md`

## Troubleshooting

**"No location updates"**

- Check permissions in Settings → Your App → Location
- Test on physical device, not simulator
- Ensure `NKWalk.startTracking()` was called

**"Floor always 0"**

- Floor detection requires supported venue
- Needs device with barometer (iPhone 6+)
- Wait 30 seconds for sensor initialization

**"Initialization failed"**

- Verify API key is correct
- Check backend endpoints are accessible
- Review console logs for specific error

---

**You're all set!** Your app is now tracking indoor location. 🎉
