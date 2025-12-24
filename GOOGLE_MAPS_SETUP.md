# Google Maps Indoor - Setup Guide

## Overview

The NKWalk SDK now uses **Google Maps** as the primary indoor location provider. Google Maps provides:

- ✅ **Indoor floor plans** for thousands of venues worldwide
- ✅ **Automatic floor detection** using device sensors
- ✅ **No venue fingerprinting** required
- ✅ **Works with standard CoreLocation** API
- ✅ **Easy integration** - just add API key

## 🚀 Quick Setup (5 Minutes)

### Step 1: Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (or select existing)
3. **Enable APIs**:
   - Maps SDK for iOS
   - (Optional) Places API for venue search
4. **Create API Key**:
   - Navigate to "Credentials"
   - Click "Create Credentials" → "API Key"
   - Click "Restrict Key"
   - Under "Application restrictions", select "iOS apps"
   - Add your app's bundle ID
   - Under "API restrictions", select "Restrict key"
   - Select "Maps SDK for iOS"
   - Save

### Step 2: Configure Backend

Update your backend configuration endpoint to return:

```json
{
  "api_key": "your_nkwalk_api_key",
  "providers": [
    {
      "type": "google_maps",
      "enabled": true,
      "credentials": {
        "api_key": "YOUR_GOOGLE_MAPS_API_KEY"
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
    "bluetooth_enabled": false,
    "analytics_enabled": true,
    "debug_logging_enabled": false
  }
}
```

### Step 3: Add to Your iOS App

**That's it!** The SDK already includes Google Maps support. Just:

1. Add NKWalk SDK to your project (as described in READY_TO_USE.md)
2. Initialize with your API key
3. SDK will automatically use Google Maps for indoor positioning

```swift
import NKWalk

NKWalk.initialize(apiKey: "YOUR_NKWALK_API_KEY") { result in
    switch result {
    case .success:
        print("✅ SDK with Google Maps ready")
    case .failure(let error):
        print("❌ Error: \(error)")
    }
}

// Start tracking
NKWalk.setEventDelegate(self)
try NKWalk.startTracking()
```

## 🗺️ How It Works

### Indoor Floor Detection

Google Maps uses device sensors to detect floor levels in supported venues:

1. **Barometer**: Measures air pressure changes for floor detection
2. **WiFi**: Uses WiFi SSID/BSSID patterns
3. **Cellular**: Cell tower signal strength patterns
4. **Bluetooth**: BLE beacon signals (if available)

### Supported Venues

Google automatically provides indoor maps for:

- 🛫 Major airports worldwide
- 🏬 Shopping malls
- 🏟️ Stadiums and arenas
- 🏛️ Museums
- 🏨 Hotels
- 🏥 Hospitals
- 🚇 Transit stations
- 📚 Universities

Check venue availability: [Google Maps Indoor](https://www.google.com/maps/about/partners/indoormaps/)

### Location Updates

You'll receive location updates with floor information:

```swift
func nkWalk(didUpdateLocation location: LocationData) {
    print("Provider: \(location.provider)")  // "google_maps"
    print("Latitude: \(location.latitude)")
    print("Longitude: \(location.longitude)")
    print("Floor: \(location.floor ?? 0)")    // Floor level
    print("Accuracy: \(location.accuracy)m")

    // Check metadata
    if location.metadata["floor_detected"] == "true" {
        print("✅ Indoor floor detected")
    }
}
```

## 📋 Permissions Required

Add to your `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location for indoor navigation</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location for continuous indoor positioning</string>

<!-- Optional but recommended for better floor detection -->
<key>NSMotionUsageDescription</key>
<string>We use motion sensors to improve floor detection accuracy</string>
```

## 🎯 Testing

### Test on Physical Device

**Important**: Indoor floor detection requires a **physical device** with:

- Barometer sensor (iPhone 6 and later)
- Location services enabled
- Being in a Google Maps-supported venue

### Test Locations

Try these well-known venues with Google indoor maps:

- San Francisco International Airport (SFO)
- Los Angeles International Airport (LAX)
- Westfield San Francisco Centre
- Mall of America

### Verify Floor Detection

```swift
class TestViewController: UIViewController, NKWalkEventDelegate {

    func nkWalk(didUpdateLocation location: LocationData) {
        // Floor changes
        if location.metadata["event_type"] == "floor_change" {
            print("🚶 Changed to floor: \(location.floor ?? 0)")
        }

        // Check if floor is detected
        if let floor = location.floor {
            print("✅ Floor detected: \(floor)")
        } else {
            print("⚠️ No floor information (outdoor or unsupported venue)")
        }
    }
}
```

## 🔄 Provider Fallback

The SDK supports multiple providers with automatic fallback:

### Priority Order

1. **Google Maps** (Primary) - For venues with Google indoor maps
2. **CoreLocation** (Fallback) - Basic GPS positioning
3. **IndoorAtlas** (Optional) - If you need custom venue mapping

### Configuration Example

```json
{
  "providers": [
    {
      "type": "google_maps",
      "enabled": true,
      "credentials": { "api_key": "GOOGLE_KEY" }
    },
    {
      "type": "core_location",
      "enabled": true,
      "credentials": {}
    }
  ]
}
```

The SDK will try Google Maps first, fall back to CoreLocation if needed.

## 💰 Pricing

### Google Maps Platform

- **Maps SDK for iOS**: $7 per 1,000 loads
- **Free tier**: $200 credit per month (~28,000 map loads/month free)
- **Indoor data**: Included at no additional cost

### Cost Optimization

```json
{
  "features": {
    "cache_maps": true,
    "preload_venues": ["venue_id_1", "venue_id_2"]
  }
}
```

## 📊 Comparison: Google Maps vs IndoorAtlas

| Feature            | Google Maps         | IndoorAtlas  |
| ------------------ | ------------------- | ------------ |
| **Setup Time**     | 5 minutes           | Days/weeks   |
| **Venue Coverage** | Thousands worldwide | Custom only  |
| **Accuracy**       | 5-10 meters         | 1-2 meters   |
| **Fingerprinting** | Not required        | Required     |
| **Cost**           | Pay per use         | Subscription |
| **Integration**    | Very easy           | Complex      |
| **Maintenance**    | Google handles      | You handle   |

## 🆘 Troubleshooting

### Floor not detected

**Possible causes:**

- Venue not supported by Google
- Device doesn't have barometer
- Indoor mode not enabled
- Testing on simulator (won't work)

**Solutions:**

- Test on real device
- Verify venue is in Google Maps app
- Enable location permissions
- Move to different floor to trigger detection

### API key not working

**Check:**

1. API key restrictions match your bundle ID
2. Maps SDK for iOS is enabled
3. Billing account is active (required even for free tier)
4. No quota limits exceeded

### Low accuracy indoors

**Improve:**

1. Enable motion sensors permission
2. Ensure WiFi is on (even if not connected)
3. Allow location calibration
4. Wait for sensor stabilization (~30 seconds)

## 🎓 Best Practices

### 1. Request Permissions Early

```swift
// In AppDelegate
func application(...) -> Bool {
    // Request location permission at app start
    let locationManager = CLLocationManager()
    locationManager.requestWhenInUseAuthorization()
    return true
}
```

### 2. Handle Permission Denials Gracefully

```swift
func nkWalk(didFailWithError error: NKWalkError) {
    if case .permissionDenied(let permission) = error {
        // Show user-friendly message
        showPermissionAlert(for: permission)
    }
}
```

### 3. Preload Venue Data

If you know which venues users will visit:

```json
{
  "settings": {
    "preload_venues": [
      "ChIJ...", // Google Place ID
      "ChIJ..."
    ]
  }
}
```

### 4. Monitor Battery Usage

```swift
// Reduce update frequency when battery is low
if ProcessInfo.processInfo.isLowPowerModeEnabled {
    // SDK automatically adjusts
}
```

## 📚 Resources

- **Google Maps Platform**: https://developers.google.com/maps/documentation/ios-sdk
- **Indoor Maps**: https://www.google.com/maps/about/partners/indoormaps/
- **Pricing**: https://cloud.google.com/maps-platform/pricing
- **Support**: https://developers.google.com/maps/support

## ✅ Quick Checklist

- [ ] Google Cloud project created
- [ ] Maps SDK for iOS enabled
- [ ] API key created with iOS restrictions
- [ ] Bundle ID added to API key restrictions
- [ ] Backend configured with Google API key
- [ ] NKWalk SDK added to iOS app
- [ ] Permissions added to Info.plist
- [ ] Tested on physical device
- [ ] Tested in supported venue
- [ ] Floor changes detected correctly

---

**You're all set!** Google Maps indoor positioning is now integrated with NKWalk SDK. The SDK will automatically handle floor detection, accuracy optimization, and seamless indoor/outdoor transitions.
