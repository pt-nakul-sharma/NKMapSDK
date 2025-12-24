import UIKit
import NKWalk
import MapKit

class MainViewController: UIViewController {

    private let statusLabel = UILabel()
    private let initButton = UIButton(type: .system)
    private let startTrackingButton = UIButton(type: .system)
    private let stopTrackingButton = UIButton(type: .system)
    private let floorLabel = UILabel()
    private let accuracyLabel = UILabel()
    private let coordinateLabel = UILabel()

    private var mapView: NKWalkMapView?

    private let apiKey = "YOUR_API_KEY_HERE"

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "NKWalk Demo"
        view.backgroundColor = .systemBackground

        setupUI()
    }

    private func setupUI() {
        statusLabel.text = "Status: Not Initialized"
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 16, weight: .medium)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        initButton.setTitle("Initialize SDK", for: .normal)
        initButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        initButton.addTarget(self, action: #selector(initializeSDK), for: .touchUpInside)
        initButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(initButton)

        startTrackingButton.setTitle("Start Tracking", for: .normal)
        startTrackingButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        startTrackingButton.addTarget(self, action: #selector(startTracking), for: .touchUpInside)
        startTrackingButton.isEnabled = false
        startTrackingButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(startTrackingButton)

        stopTrackingButton.setTitle("Stop Tracking", for: .normal)
        stopTrackingButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        stopTrackingButton.addTarget(self, action: #selector(stopTracking), for: .touchUpInside)
        stopTrackingButton.isEnabled = false
        stopTrackingButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stopTrackingButton)

        let stackView = UIStackView(arrangedSubviews: [
            statusLabel,
            initButton,
            startTrackingButton,
            stopTrackingButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        floorLabel.text = "Floor: --"
        floorLabel.font = .systemFont(ofSize: 14)
        floorLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(floorLabel)

        accuracyLabel.text = "Accuracy: --"
        accuracyLabel.font = .systemFont(ofSize: 14)
        accuracyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(accuracyLabel)

        coordinateLabel.text = "Coordinates: --"
        coordinateLabel.font = .systemFont(ofSize: 14)
        coordinateLabel.numberOfLines = 0
        coordinateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(coordinateLabel)

        let infoStack = UIStackView(arrangedSubviews: [
            floorLabel,
            accuracyLabel,
            coordinateLabel
        ])
        infoStack.axis = .vertical
        infoStack.spacing = 8
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(infoStack)

        let mapContainer = UIView()
        mapContainer.backgroundColor = .systemGray6
        mapContainer.layer.cornerRadius = 12
        mapContainer.clipsToBounds = true
        mapContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapContainer)

        let mapView = NKWalkMapView()
        mapView.delegate = self
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapContainer.addSubview(mapView)
        self.mapView = mapView

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            infoStack.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            infoStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            mapContainer.topAnchor.constraint(equalTo: infoStack.bottomAnchor, constant: 20),
            mapContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mapContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mapContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            mapView.topAnchor.constraint(equalTo: mapContainer.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: mapContainer.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: mapContainer.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: mapContainer.bottomAnchor)
        ])
    }

    @objc private func initializeSDK() {
        initButton.isEnabled = false
        statusLabel.text = "Status: Initializing..."

        NKWalk.initialize(apiKey: apiKey) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.statusLabel.text = "Status: Initialized ✓"
                self.initButton.isEnabled = false
                self.startTrackingButton.isEnabled = true

                NKWalk.setEventDelegate(self)

                self.showAlert(title: "Success", message: "SDK initialized successfully!")

            case .failure(let error):
                self.statusLabel.text = "Status: Initialization Failed"
                self.initButton.isEnabled = true

                self.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }

    @objc private func startTracking() {
        do {
            try NKWalk.startTracking()
            statusLabel.text = "Status: Tracking..."
            startTrackingButton.isEnabled = false
            stopTrackingButton.isEnabled = true
        } catch {
            showAlert(title: "Error", message: error.localizedDescription)
        }
    }

    @objc private func stopTracking() {
        NKWalk.stopTracking()
        statusLabel.text = "Status: Stopped"
        startTrackingButton.isEnabled = true
        stopTrackingButton.isEnabled = false
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension MainViewController: NKWalkEventDelegate {
    func nkWalk(didUpdateLocation location: LocationData) {
        coordinateLabel.text = String(format: "Lat: %.6f, Lon: %.6f", location.latitude, location.longitude)
        accuracyLabel.text = String(format: "Accuracy: %.2fm", location.accuracy)

        if let floor = location.floor {
            floorLabel.text = "Floor: \(floor)"
        } else {
            floorLabel.text = "Floor: --"
        }

        mapView?.setCenter(location.coordinate, animated: true)

        let annotation = NKWalkAnnotation(
            coordinate: location.coordinate,
            title: "Current Location",
            subtitle: "Floor \(location.floor ?? 0)",
            floor: location.floor,
            color: .systemBlue
        )
        mapView?.addAnnotation(annotation)
    }

    func nkWalk(didFailWithError error: NKWalkError) {
        print("Location error: \(error.localizedDescription)")
    }

    func nkWalk(didChangeTrackingState isTracking: Bool) {
        statusLabel.text = isTracking ? "Status: Tracking..." : "Status: Stopped"
    }
}

extension MainViewController: NKWalkMapViewDelegate {
    func mapView(_ mapView: NKWalkMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        print("Tapped at: \(coordinate.latitude), \(coordinate.longitude)")
    }

    func mapView(_ mapView: NKWalkMapView, didSelectAnnotation annotation: NKWalkAnnotation) {
        print("Selected annotation: \(annotation.title ?? "Unknown")")
    }
}
