import Foundation
import Photos

extension PHAsset {
    var _coordinates: String {
        if let coordinates = location?.coordinate {
            return _stringify(coordinates: coordinates)
        } else {
            return ""
        }
    }

    private func _stringify(coordinates: CLLocationCoordinate2D) -> String {
        return "\(coordinates.latitude), \(coordinates.longitude)"
    }
}
