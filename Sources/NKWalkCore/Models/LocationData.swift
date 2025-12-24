import Foundation
import CoreLocation

public struct LocationData: Codable {
    public let id: UUID
    public let timestamp: Date
    public let latitude: Double
    public let longitude: Double
    public let floor: Int?
    public let accuracy: Double
    public let heading: Double?
    public let speed: Double?
    public let provider: String
    public let metadata: [String: String]

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        latitude: Double,
        longitude: Double,
        floor: Int? = nil,
        accuracy: Double,
        heading: Double? = nil,
        speed: Double? = nil,
        provider: String,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.floor = floor
        self.accuracy = accuracy
        self.heading = heading
        self.speed = speed
        self.provider = provider
        self.metadata = metadata
    }

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

public struct LocationEvent: Codable {
    public let location: LocationData
    public let eventType: EventType
    public let queuedAt: Date
    public var retryCount: Int
    public var lastRetryAt: Date?

    public init(
        location: LocationData,
        eventType: EventType = .position,
        queuedAt: Date = Date(),
        retryCount: Int = 0,
        lastRetryAt: Date? = nil
    ) {
        self.location = location
        self.eventType = eventType
        self.queuedAt = queuedAt
        self.retryCount = retryCount
        self.lastRetryAt = lastRetryAt
    }
}

public enum EventType: String, Codable {
    case position
    case enter
    case exit
    case floorChange
}
