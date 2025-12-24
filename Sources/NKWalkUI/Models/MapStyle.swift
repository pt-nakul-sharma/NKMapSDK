import UIKit

public enum MapStyle {
    case standard
    case satellite
    case hybrid
    case custom(CustomMapStyle)
}

public struct CustomMapStyle {
    public let backgroundColor: UIColor
    public let roadColor: UIColor
    public let buildingColor: UIColor
    public let labelColor: UIColor

    public init(
        backgroundColor: UIColor = .white,
        roadColor: UIColor = .gray,
        buildingColor: UIColor = .lightGray,
        labelColor: UIColor = .black
    ) {
        self.backgroundColor = backgroundColor
        self.roadColor = roadColor
        self.buildingColor = buildingColor
        self.labelColor = labelColor
    }
}
