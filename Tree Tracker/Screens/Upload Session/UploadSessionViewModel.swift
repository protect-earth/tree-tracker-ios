import Foundation
import class UIKit.UIImage
import class CoreLocation.CLLocation
import class Photos.PHAsset

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

    func startTrackLocation()
    func stopTrackingLocation()
}

import CoreLocation

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

    func startTrackLocation() {
        manager.startUpdatingLocation()
    }

    func stopTrackingLocation() {
        manager.stopUpdatingLocation()
    }
}

protocol UploadSessionNavigating: AnyObject {
    func triggerAskForDetailsAndStoreFlow(assets: [PHAsset], completion: @escaping (Bool) -> Void)
}

final class UploadSessionViewModel {
    enum State {
        case actionButton(ButtonModel)
        case takeAPicture(cancel: () -> Void, completion: (Result<UIImage, Error>) -> Void)
    }

    @DelayedPublished var state: State
    @DelayedPublished var alert: AlertModel

    private let navigation: UploadSessionNavigating
    private let assetManager: AssetManaging
    private let locationManager: LocationProviding & PermissionAsking

    init(navigation: UploadSessionNavigating, assetManager: AssetManaging = PHAssetManager(), locationManager: LocationProviding & PermissionAsking = LocationManager()) {
        self.navigation = navigation
        self.assetManager = assetManager
        self.locationManager = locationManager
    }

    func onLoad() {
        presentButtons()
    }

    func onAppear() {}

    private func presentButtons() {
        locationManager.stopTrackingLocation()
        state = .actionButton(
            ButtonModel(
                title: .text("Start new session"),
                action: { [weak self] in
                    self?.askForPermissionsIfNeededAndStartNewSession()
                },
                isEnabled: true
            )
        )
    }

    private func askForPermissionsIfNeededAndStartNewSession() {
        switch locationManager.status {
        case .authorized:
            startNewSession()
        case .denied:
            alert = .init(title: "Permissions error", message:  "We need camera and location permissions in order to properly add photo with coordinates. Please enable that in Tree Tracker app Settings (iOS Settings -> Tree Tracker)", buttons: [.init(title: "Ok", style: .default, action: nil)])
        case .unknown:
            locationManager.request { [weak self] _ in
                self?.askForPermissionsIfNeededAndStartNewSession()
            }
        }
    }

    private func startNewSession() {
        locationManager.startTrackLocation()
        state = .takeAPicture { [weak self] in
            self?.presentButtons()
        } completion: { [weak self] result in
            switch result {
            case let .success(image):
                self?.store(image: image, location: self?.locationManager.currentLocation)
            case let .failure(error):
                self?.alert = .init(title: "Error", message: "Error happened while capturing an image. \n Details: \(error)", buttons: [.init(title: "Ok", style: .default, action: nil)])
            }
        }
    }

    private func stopSession() {
        presentButtons()
    }

    private func store(image: UIImage, location: CLLocation?) {
        assetManager.save(image: image, location: location) { [weak self] result in
            switch result {
            case let .success(asset):
                self?.navigation.triggerAskForDetailsAndStoreFlow(assets: [asset]) { _ in
                    self?.askForPermissionsIfNeededAndStartNewSession()
                }
            case let .failure(error):
                self?.alert = .init(title: "Error", message: "Error happened while capturing an image. \n Details: \(error)", buttons: [.init(title: "Ok", style: .default, action: nil)])
            }
        }
    }
}
