import Foundation

public struct Configuration: Codable {
    public let apiKey: String
    public let providers: [LocationProviderConfig]
    public let endpoints: Endpoints
    public let syncSettings: SyncSettings
    public let features: FeatureFlags

    public init(
        apiKey: String,
        providers: [LocationProviderConfig],
        endpoints: Endpoints,
        syncSettings: SyncSettings,
        features: FeatureFlags
    ) {
        self.apiKey = apiKey
        self.providers = providers
        self.endpoints = endpoints
        self.syncSettings = syncSettings
        self.features = features
    }
}

public struct LocationProviderConfig: Codable {
    public let type: ProviderType
    public let credentials: [String: String]
    public let settings: [String: AnyCodable]
    public let enabled: Bool

    public init(
        type: ProviderType,
        credentials: [String: String],
        settings: [String: AnyCodable],
        enabled: Bool
    ) {
        self.type = type
        self.credentials = credentials
        self.settings = settings
        self.enabled = enabled
    }
}

public enum ProviderType: String, Codable {
    case googleMaps = "google_maps"
    case coreLocation = "core_location"
    case indoorAtlas = "indoor_atlas"  // Reserved for future implementation
    case custom = "custom"
}

public struct Endpoints: Codable {
    public let authValidate: String
    public let configuration: String
    public let eventsBatch: String
    public let eventsSingle: String

    public init(
        authValidate: String,
        configuration: String,
        eventsBatch: String,
        eventsSingle: String
    ) {
        self.authValidate = authValidate
        self.configuration = configuration
        self.eventsBatch = eventsBatch
        self.eventsSingle = eventsSingle
    }
}

public struct SyncSettings: Codable {
    public let batchSize: Int
    public let syncIntervalSeconds: TimeInterval
    public let maxRetryAttempts: Int
    public let retryBackoffMultiplier: Double
    public let compressionEnabled: Bool
    public let wifiOnlySync: Bool

    public init(
        batchSize: Int = 50,
        syncIntervalSeconds: TimeInterval = 30,
        maxRetryAttempts: Int = 3,
        retryBackoffMultiplier: Double = 2.0,
        compressionEnabled: Bool = true,
        wifiOnlySync: Bool = false
    ) {
        self.batchSize = batchSize
        self.syncIntervalSeconds = syncIntervalSeconds
        self.maxRetryAttempts = maxRetryAttempts
        self.retryBackoffMultiplier = retryBackoffMultiplier
        self.compressionEnabled = compressionEnabled
        self.wifiOnlySync = wifiOnlySync
    }
}

public struct FeatureFlags: Codable {
    public let backgroundLocationEnabled: Bool
    public let bluetoothEnabled: Bool
    public let analyticsEnabled: Bool
    public let debugLoggingEnabled: Bool

    public init(
        backgroundLocationEnabled: Bool = false,
        bluetoothEnabled: Bool = true,
        analyticsEnabled: Bool = true,
        debugLoggingEnabled: Bool = false
    ) {
        self.backgroundLocationEnabled = backgroundLocationEnabled
        self.bluetoothEnabled = bluetoothEnabled
        self.analyticsEnabled = analyticsEnabled
        self.debugLoggingEnabled = debugLoggingEnabled
    }
}

public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported type"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unsupported type"
                )
            )
        }
    }
}
