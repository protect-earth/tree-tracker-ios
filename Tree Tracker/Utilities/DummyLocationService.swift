import Foundation
import CoreLocation

class DummyLocationService: LocationService {
    
    enum AccuracyMode {
        case accurate
        case inaccurate
    }
    
    var currentLocation: CLLocation? {
        switch accuracyMode {
        case .accurate:
            return CLLocation(latitude: 0, longitude: 0)
        case .inaccurate:
            let loc = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                 altitude: 0,
                                 horizontalAccuracy: 1500,
                                 verticalAccuracy: 1,
                                 timestamp: Date())
            return loc
        }
    }
    
    var accuracyMode: AccuracyMode = .accurate
    
    func startTrackLocation() {
    }
    
    func stopTrackingLocation() {
    }
    
    var status: PermissionStatus = .authorized
    
    func request(completion: (PermissionStatus) -> Void) {
    }
    
}
