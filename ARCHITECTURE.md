# NKWalk SDK Architecture

## Overview

NKWalk is an offline-first indoor intelligence SDK that abstracts IndoorAtlas functionality behind a clean facade pattern, providing host apps with single-line initialization and automatic data synchronization.

## Core Architecture

### 1. Facade Layer (Public API)

```swift
// Single-line initialization
NKWalk.initialize(apiKey: "YOUR_API_KEY")

// Unified map view
let mapView = NKWalkMapView(frame: bounds)
```

### 2. Module Structure

```
NKWalk (Swift Package)
├── Sources/
│   ├── NKWalk/                    # Main facade module
│   │   ├── NKWalk.swift           # Primary entry point
│   │   ├── NKWalkMapView.swift    # Unified map component
│   │   └── NKWalkError.swift      # Public error types
│   ├── NKWalkCore/                # Internal core logic
│   │   ├── Configuration/
│   │   │   ├── ConfigurationManager.swift
│   │   │   └── ConfigurationModels.swift
│   │   ├── Authentication/
│   │   │   ├── AuthenticationService.swift
│   │   │   └── TokenManager.swift
│   │   ├── Networking/
│   │   │   ├── NetworkManager.swift
│   │   │   ├── EventQueue.swift
│   │   │   ├── BatchUploader.swift
│   │   │   └── ReachabilityMonitor.swift
│   │   ├── Location/
│   │   │   ├── LocationProviderProtocol.swift
│   │   │   ├── IndoorAtlasProvider.swift
│   │   │   ├── PermissionManager.swift
│   │   │   └── LocationDataModel.swift
│   │   ├── Storage/
│   │   │   ├── LocalStorageManager.swift
│   │   │   ├── EventStore.swift
│   │   │   └── CacheManager.swift
│   │   └── Lifecycle/
│   │       ├── StateManager.swift
│   │       └── BatteryOptimizer.swift
│   └── NKWalkUI/                  # UI components
│       ├── MapRenderer/
│       │   ├── MapViewDelegate.swift
│       │   └── MapStyleManager.swift
│       └── Annotations/
│           └── AnnotationFactory.swift
├── Tests/
│   ├── NKWalkTests/
│   └── NKWalkCoreTests/
├── Examples/
│   └── NKWalkDemo/                # Minimal demo app
│       ├── NKWalkDemo.xcodeproj
│       └── Sources/
└── Package.swift
```

## 3. Key Components

### A. Facade Pattern (NKWalk.swift)

**Purpose**: Single entry point that orchestrates all internal modules

**Responsibilities**:

- API key validation
- Configuration fetching from backend
- Automatic initialization of IndoorAtlas
- Lifecycle management
- Thread-safe singleton pattern

**Public API**:

```swift
public class NKWalk {
    public static func initialize(
        apiKey: String,
        completion: @escaping (Result<Void, NKWalkError>) -> Void
    )

    public static func shutdown()
    public static var isInitialized: Bool { get }
    public static var configuration: Configuration? { get }
}
```

### B. Configuration Management

**Purpose**: Retrieve and cache backend configuration

**Flow**:

1. Validate API key format
2. Authenticate with backend (`POST /api/v1/auth/validate`)
3. Fetch configuration profile (`GET /api/v1/config`)
4. Parse provider settings (IndoorAtlas credentials, map URLs)
5. Cache configuration locally with expiry

**Configuration Model**:

```swift
struct Configuration: Codable {
    let apiKey: String
    let providers: [LocationProvider]
    let endpoints: Endpoints
    let syncSettings: SyncSettings
    let features: FeatureFlags
}

struct LocationProvider: Codable {
    let type: ProviderType // .indoorAtlas
    let credentials: [String: String]
    let settings: [String: Any]
}
```

### C. Offline-First Networking

**Purpose**: Resilient data synchronization with store-and-forward

**Components**:

1. **Event Queue**:

   - Thread-safe in-memory queue
   - Persistent disk-backed storage (Core Data/SQLite)
   - Priority-based ordering
   - Automatic retry with exponential backoff

2. **Batch Uploader**:

   - Configurable batch size (default: 50 events)
   - Smart batching based on network conditions
   - Compression for large payloads
   - Deduplication

3. **Reachability Monitor**:
   - Network.framework integration
   - WiFi vs cellular detection
   - Automatic upload triggering on connectivity

**Event Model**:

```swift
struct LocationEvent: Codable {
    let id: UUID
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let floor: Int?
    let accuracy: Double
    let provider: String
    let metadata: [String: String]
}
```

### D. IndoorAtlas Provider Wrapper

**Purpose**: Abstract IndoorAtlas SDK behind protocol

**Protocol**:

```swift
protocol LocationProvider {
    func start() throws
    func stop()
    var delegate: LocationProviderDelegate? { get set }
    var status: LocationProviderStatus { get }
}

protocol LocationProviderDelegate: AnyObject {
    func locationProvider(
        _ provider: LocationProvider,
        didUpdateLocation location: LocationData
    )
    func locationProvider(
        _ provider: LocationProvider,
        didFailWithError error: Error
    )
}
```

**Implementation**:

```swift
internal class IndoorAtlasProvider: LocationProvider {
    private var iaLocationManager: IALocationManager?

    func start() throws {
        // Initialize IALocationManager with credentials
        // Set delegates
        // Start positioning
    }
}
```

### E. Permission Management

**Purpose**: Defensive permission handling

**Strategy**:

- Check current authorization status before requesting
- Provide permission rationale to host app
- Handle all states: notDetermined, denied, restricted, authorized
- Never crash on permission denial
- Graceful degradation

**Implementation**:

```swift
internal class PermissionManager {
    func requestLocationPermission(
        completion: @escaping (PermissionStatus) -> Void
    )

    func requestBluetoothPermission(
        completion: @escaping (PermissionStatus) -> Void
    )

    func checkAllPermissions() -> [Permission: PermissionStatus]
}
```

### F. NKWalkMapView Component

**Purpose**: Unified map view abstraction

**Features**:

- SwiftUI and UIKit compatible
- Customizable styling
- Annotation management
- User location tracking
- Floor switching
- Gesture handling

**Public API**:

```swift
public class NKWalkMapView: UIView {
    public var delegate: NKWalkMapViewDelegate?
    public var style: MapStyle

    public func setCenter(_ coordinate: CLLocationCoordinate2D, animated: Bool)
    public func addAnnotation(_ annotation: NKWalkAnnotation)
    public func setFloor(_ floor: Int)
}

public protocol NKWalkMapViewDelegate: AnyObject {
    func mapView(_ mapView: NKWalkMapView, didTapAt coordinate: CLLocationCoordinate2D)
    func mapView(_ mapView: NKWalkMapView, didSelectAnnotation annotation: NKWalkAnnotation)
}
```

### G. State & Lifecycle Management

**Purpose**: Handle app lifecycle transitions

**Scenarios**:

1. **Foreground → Background**:

   - Flush event queue
   - Reduce location update frequency
   - Stop non-essential services

2. **Background → Foreground**:

   - Resume normal update frequency
   - Sync queued events
   - Check for configuration updates

3. **App Termination**:
   - Persist all queued events
   - Clean shutdown of providers

**Battery Optimization**:

- Adaptive update frequency
- WiFi-only sync option
- Background task management
- Significant location change mode

## 4. Data Flow

### Initialization Flow

```
1. Host App: NKWalk.initialize(apiKey: "...")
2. NKWalk validates API key format
3. AuthenticationService.authenticate(apiKey)
   └─> POST /api/v1/auth/validate
4. ConfigurationManager.fetchConfig()
   └─> GET /api/v1/config
5. Parse provider credentials
6. Initialize IndoorAtlasProvider with credentials
7. Start LocationProvider
8. Register lifecycle observers
9. Return success to host app
```

### Location Update Flow

```
1. IndoorAtlas SDK → location update
2. IndoorAtlasProvider receives update
3. Transform to LocationData model
4. EventQueue.enqueue(locationEvent)
5. Persist to local storage
6. Check network connectivity
7. If online → BatchUploader.uploadBatch()
   └─> POST /api/v1/events/batch
8. On success → remove from queue
9. On failure → retry with backoff
```

## 5. Error Handling

### Error Types

```swift
public enum NKWalkError: Error {
    case invalidAPIKey
    case authenticationFailed(reason: String)
    case configurationFailed(reason: String)
    case networkError(underlying: Error)
    case locationProviderError(underlying: Error)
    case permissionDenied(permission: Permission)
    case notInitialized
    case unknown(Error)
}
```

### Strategy

- Never throw from public APIs (use completion handlers)
- Log all errors internally
- Provide descriptive error messages
- Graceful degradation on non-critical failures

## 6. Threading Model

- **Main Thread**: UI updates, delegate callbacks
- **Background Queue**: Networking, persistence, event processing
- **Location Queue**: IndoorAtlas callbacks (serial)

## 7. Testing Strategy

### Unit Tests

- Configuration parsing
- Event queue operations
- Batch uploader logic
- Error handling paths

### Integration Tests

- Mock backend responses
- Permission flow testing
- Lifecycle transition testing

### Performance Tests

- Event queue throughput
- Memory usage under load
- Battery consumption monitoring

## 8. Distribution

### Swift Package Manager

```swift
// Package.swift
let package = Package(
    name: "NKWalk",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "NKWalk", targets: ["NKWalk"])
    ],
    dependencies: [
        .package(url: "https://github.com/IndoorAtlas/ios-sdk", from: "3.5.0")
    ],
    targets: [
        .target(
            name: "NKWalk",
            dependencies: ["NKWalkCore", "NKWalkUI"]
        ),
        .target(
            name: "NKWalkCore",
            dependencies: [
                .product(name: "IndoorAtlas", package: "ios-sdk")
            ]
        ),
        .target(name: "NKWalkUI", dependencies: ["NKWalkCore"])
    ]
)
```

### Versioning

- Semantic versioning (MAJOR.MINOR.PATCH)
- ABI stability considerations
- Deprecation policy

## 9. Security Considerations

1. **API Key Storage**: Never log or expose in plaintext
2. **Network Communication**: TLS 1.3, certificate pinning
3. **Data Storage**: Encrypt sensitive data in local storage
4. **Access Control**: Proper `internal` vs `public` modifiers
5. **Memory Safety**: Avoid retain cycles, use weak references

## 10. Performance Targets

- **Initialization**: < 2 seconds
- **Location Update Latency**: < 100ms
- **Memory Footprint**: < 30MB baseline
- **Battery Impact**: < 5% over 8 hours of continuous use
- **Event Queue Throughput**: > 1000 events/second

## 11. Future Extensibility

### Plugin Architecture

- Support multiple location providers (e.g., Mapbox, Google)
- Provider priority and fallback logic
- Custom event types via protocol

### Analytics Integration

- Anonymous usage metrics
- Performance monitoring
- Crash reporting hooks
