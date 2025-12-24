import UIKit
import MapKit
import NKWalkCore

public final class NKWalkMapView: UIView {

    public weak var delegate: NKWalkMapViewDelegate?

    public var style: MapStyle = .standard {
        didSet {
            applyStyle()
        }
    }

    public var showsUserLocation: Bool = true {
        didSet {
            mapView.showsUserLocation = showsUserLocation
        }
    }

    public override var isUserInteractionEnabled: Bool {
        didSet {
            mapView.isUserInteractionEnabled = isUserInteractionEnabled
        }
    }

    private let mapView: MKMapView
    private var annotations: [UUID: NKWalkAnnotation] = [:]
    private var currentFloor: Int = 0

    public override init(frame: CGRect) {
        self.mapView = MKMapView(frame: frame)
        super.init(frame: frame)
        setupMapView()
    }

    public required init?(coder: NSCoder) {
        self.mapView = MKMapView()
        super.init(coder: coder)
        setupMapView()
    }

    private func setupMapView() {
        addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: topAnchor),
            mapView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        mapView.delegate = self
        mapView.showsUserLocation = showsUserLocation

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)

        applyStyle()
    }

    public func setCenter(_ coordinate: CLLocationCoordinate2D, animated: Bool) {
        mapView.setCenter(coordinate, animated: animated)
    }

    public func setRegion(_ region: MKCoordinateRegion, animated: Bool) {
        mapView.setRegion(region, animated: animated)
    }

    public func addAnnotation(_ annotation: NKWalkAnnotation) {
        annotations[annotation.id] = annotation

        if annotation.floor == nil || annotation.floor == currentFloor {
            let mkAnnotation = annotation.toMKAnnotation()
            mapView.addAnnotation(mkAnnotation)
        }
    }

    public func removeAnnotation(_ annotation: NKWalkAnnotation) {
        annotations.removeValue(forKey: annotation.id)

        if let mkAnnotation = mapView.annotations.first(where: {
            ($0 as? MKAnnotationAdapter)?.annotationId == annotation.id
        }) {
            mapView.removeAnnotation(mkAnnotation)
        }
    }

    public func removeAllAnnotations() {
        let customAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(customAnnotations)
        annotations.removeAll()
    }

    public func setFloor(_ floor: Int) {
        currentFloor = floor

        let customAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(customAnnotations)

        let visibleAnnotations = annotations.values
            .filter { $0.floor == nil || $0.floor == floor }
            .map { $0.toMKAnnotation() }

        mapView.addAnnotations(visibleAnnotations)

        delegate?.mapView(self, didChangeFloor: floor)
    }

    public func selectAnnotation(_ annotation: NKWalkAnnotation, animated: Bool) {
        if let mkAnnotation = mapView.annotations.first(where: {
            ($0 as? MKAnnotationAdapter)?.annotationId == annotation.id
        }) {
            mapView.selectAnnotation(mkAnnotation, animated: animated)
        }
    }

    public func deselectAnnotation(_ annotation: NKWalkAnnotation, animated: Bool) {
        if let mkAnnotation = mapView.annotations.first(where: {
            ($0 as? MKAnnotationAdapter)?.annotationId == annotation.id
        }) {
            mapView.deselectAnnotation(mkAnnotation, animated: animated)
        }
    }

    private func applyStyle() {
        switch style {
        case .standard:
            mapView.mapType = .standard
        case .satellite:
            mapView.mapType = .satellite
        case .hybrid:
            mapView.mapType = .hybrid
        case .custom(let config):
            mapView.mapType = .standard
            applyCustomStyle(config)
        }
    }

    private func applyCustomStyle(_ config: CustomMapStyle) {

    }

    @objc private func handleMapTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        delegate?.mapView(self, didTapAt: coordinate)
    }
}

extension NKWalkMapView: MKMapViewDelegate {
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let adapter = annotation as? MKAnnotationAdapter,
              let nkAnnotation = annotations[adapter.annotationId] else {
            return nil
        }

        let identifier = "NKWalkAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }

        annotationView?.markerTintColor = nkAnnotation.color
        annotationView?.glyphImage = nkAnnotation.icon

        return annotationView
    }

    public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let adapter = view.annotation as? MKAnnotationAdapter,
              let annotation = annotations[adapter.annotationId] else {
            return
        }

        delegate?.mapView(self, didSelectAnnotation: annotation)
    }

    public func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        guard let adapter = view.annotation as? MKAnnotationAdapter,
              let annotation = annotations[adapter.annotationId] else {
            return
        }

        delegate?.mapView(self, didDeselectAnnotation: annotation)
    }

    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        delegate?.mapView(self, regionDidChange: mapView.region)
    }
}

public protocol NKWalkMapViewDelegate: AnyObject {
    func mapView(_ mapView: NKWalkMapView, didTapAt coordinate: CLLocationCoordinate2D)
    func mapView(_ mapView: NKWalkMapView, didSelectAnnotation annotation: NKWalkAnnotation)
    func mapView(_ mapView: NKWalkMapView, didDeselectAnnotation annotation: NKWalkAnnotation)
    func mapView(_ mapView: NKWalkMapView, didChangeFloor floor: Int)
    func mapView(_ mapView: NKWalkMapView, regionDidChange region: MKCoordinateRegion)
}

public extension NKWalkMapViewDelegate {
    func mapView(_ mapView: NKWalkMapView, didTapAt coordinate: CLLocationCoordinate2D) {}
    func mapView(_ mapView: NKWalkMapView, didSelectAnnotation annotation: NKWalkAnnotation) {}
    func mapView(_ mapView: NKWalkMapView, didDeselectAnnotation annotation: NKWalkAnnotation) {}
    func mapView(_ mapView: NKWalkMapView, didChangeFloor floor: Int) {}
    func mapView(_ mapView: NKWalkMapView, regionDidChange region: MKCoordinateRegion) {}
}
