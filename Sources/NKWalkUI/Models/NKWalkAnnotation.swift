import UIKit
import MapKit
import CoreLocation

public struct NKWalkAnnotation {
    public let id: UUID
    public let coordinate: CLLocationCoordinate2D
    public let title: String?
    public let subtitle: String?
    public let floor: Int?
    public let color: UIColor
    public let icon: UIImage?

    public init(
        id: UUID = UUID(),
        coordinate: CLLocationCoordinate2D,
        title: String? = nil,
        subtitle: String? = nil,
        floor: Int? = nil,
        color: UIColor = .systemBlue,
        icon: UIImage? = nil
    ) {
        self.id = id
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.floor = floor
        self.color = color
        self.icon = icon
    }

    internal func toMKAnnotation() -> MKAnnotation {
        return MKAnnotationAdapter(annotation: self)
    }
}

internal class MKAnnotationAdapter: NSObject, MKAnnotation {
    let annotationId: UUID
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?

    init(annotation: NKWalkAnnotation) {
        self.annotationId = annotation.id
        self.coordinate = annotation.coordinate
        self.title = annotation.title
        self.subtitle = annotation.subtitle
        super.init()
    }
}
