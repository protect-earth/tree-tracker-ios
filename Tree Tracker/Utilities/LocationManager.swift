import CoreLocation

enum PermissionStatus {
    case authorized
    case denied
    case unknown
}

protocol PermissionAsking {
    var status: PermissionStatus { get }
    func request(completion: (PermissionStatus) -> Void)
}

protocol LocationProviding {
    var currentLocation: CLLocation? { get }

    func startTrackLocation(update: @escaping (CLLocation) -> Void)
    func stopTrackingLocation()
}

final class LocationManager: NSObject, PermissionAsking, LocationProviding, CLLocationManagerDelegate {
    var currentLocation: CLLocation? {
        manager.location
    }

    var status: PermissionStatus {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .unknown
        @unknown default:
            return .unknown
        }
    }

    private let manager: CLLocationManager
    private var authorizationChangeCompletion: ((PermissionStatus) -> Void)?
    private var locationDidUpdate: ((CLLocation) -> Void)?

    init(manager: CLLocationManager = CLLocationManager()) {
        self.manager = manager
        super.init()

        self.manager.delegate = self
    }

    func request(completion: (PermissionStatus) -> Void) {
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationChangeCompletion?(status)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationDidUpdate?(locations.last!)
    }

    func startTrackLocation(update: @escaping (CLLocation) -> Void) {
        manager.startUpdatingLocation()
        self.locationDidUpdate = update
    }

    func stopTrackingLocation() {
        manager.stopUpdatingLocation()
    }
}
