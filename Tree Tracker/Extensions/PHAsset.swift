import Foundation
import Photos

extension PHAsset {
    func stringifyCoordinates(roundingPrecision: Int = 5) -> String {
        if let coordinates = location?.coordinate {
            return _stringify(coordinates: coordinates, roundingPrecision: roundingPrecision)
        } else {
            return ""
        }
    }

    private func _stringify(coordinates: CLLocationCoordinate2D, roundingPrecision: Int) -> String {
        return String(format: "%.\(roundingPrecision)f, %.\(roundingPrecision)f", coordinates.latitude, coordinates.longitude)
    }
}
