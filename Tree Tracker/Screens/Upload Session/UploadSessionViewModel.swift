import Foundation
import class UIKit.UIImage
import class CoreLocation.CLLocation
import class Photos.PHAsset

protocol UploadSessionNavigating: AnyObject {
    func triggerAskForDetailsAndStoreFlow(assets: [PHAsset], site: Site?, supervisor: Supervisor?, completion: @escaping (Bool) -> Void)
}

final class UploadSessionViewModel {
    enum State {
        case actionButton(ButtonModel)
        case takeAPicture(cancel: () -> Void, completion: (Result<UIImage, Error>) -> Void)
    }

    @DelayedPublished var state: State
    @DelayedPublished var alert: AlertModel
    @DelayedPublished var fields: [TextFieldModel]
    
    private let navigation: UploadSessionNavigating
    private let assetManager: AssetManaging
    private let database: Database
    private let locationManager: LocationProviding & PermissionAsking
    private var sites: [Site] = []
    private var supervisors: [Supervisor] = []

    init(navigation: UploadSessionNavigating, assetManager: AssetManaging = PHAssetManager(), database: Database = CurrentEnvironment.database, locationManager: LocationProviding & PermissionAsking = LocationManager()) {
        self.navigation = navigation
        self.assetManager = assetManager
        self.database = database
        self.locationManager = locationManager
    }

    func onLoad() {}
    
    private func fetchDatabaseContent(completion: @escaping () -> Void) {
        database.fetch(Site.self, Supervisor.self) { [weak self] sites, supervisors in
            self?.sites = sites.sorted(by: \.name, order: .ascending)
            self?.supervisors = supervisors.sorted(by: \.name, order: .ascending)
            completion()
        }
    }

    func onAppear() {
        fetchDatabaseContent { [weak self] in
            self?.presentContent()
        }
    }

    private func presentContent(supervisor: Supervisor? = nil, site: Site? = nil) {
        locationManager.stopTrackingLocation()
        
        var supervisor: Supervisor? = supervisor
        var site: Site? = site
        
        fields = [
            .init(placeholder: "Supervisor",
                  text: supervisor?.name,
                  input: .keyboard(.selection(
                                    ["--"] + self.supervisors.map(\.name),
                                    initialIndexSelected: supervisors.firstIndex { $0.id == supervisor?.id }.map { $0 + 1 },
                                    indexSelected: { [weak self] selectedSupervisor in
                                        supervisor = self?.supervisors[safe: selectedSupervisor - 1]
                                        self?.presentContent(supervisor: supervisor, site: site)
                                    }),
                                   .done()),
                  returnKey: .done,
                  onChange: { _ in }),
            .init(placeholder: "Site",
                  text: site?.name,
                  input: .keyboard(.selection(
                                    ["--"] + self.sites.map(\.name),
                                    initialIndexSelected: sites.firstIndex { $0.id == site?.id }.map { $0 + 1 },
                                    indexSelected: { [weak self] selectedSite in
                                        site = self?.sites[safe: selectedSite - 1]
                                        self?.presentContent(supervisor: supervisor, site: site)
                                    }),
                                   .done()),
                  returnKey: .done,
                  onChange: { _ in }),
        ]
        state = .actionButton(
            ButtonModel(
                title: .text("Start new session"),
                action: { [weak self] in
                    self?.askForPermissionsIfNeededAndStartNewSession(site: site, supervisor: supervisor)
                },
                isEnabled: true
            )
        )
    }

    private func askForPermissionsIfNeededAndStartNewSession(site: Site?, supervisor: Supervisor?) {
        switch locationManager.status {
        case .authorized:
            startNewSession(site: site, supervisor: supervisor)
        case .denied:
            alert = .init(title: "Permissions error", message:  "We need camera and location permissions in order to properly add photo with coordinates. Please enable that in Tree Tracker app Settings (iOS Settings -> Tree Tracker)", buttons: [.init(title: "Ok", style: .default, action: nil)])
        case .unknown:
            locationManager.request { [weak self] _ in
                self?.askForPermissionsIfNeededAndStartNewSession(site: site, supervisor: supervisor)
            }
        }
    }

    private func startNewSession(site: Site?, supervisor: Supervisor?) {
        locationManager.startTrackLocation()
        state = .takeAPicture { [weak self] in
            self?.presentContent()
        } completion: { [weak self] result in
            switch result {
            case let .success(image):
                self?.store(image: image, location: self?.locationManager.currentLocation, site: site, supervisor: supervisor)
            case let .failure(error):
                self?.alert = .init(title: "Error", message: "Error happened while capturing an image. \n Details: \(error)", buttons: [.init(title: "Ok", style: .default, action: nil)])
            }
        }
    }

    private func stopSession() {
        presentContent()
    }

    private func store(image: UIImage, location: CLLocation?, site: Site?, supervisor: Supervisor?) {
        assetManager.save(image: image, location: location) { [weak self] result in
            switch result {
            case let .success(asset):
                self?.navigation.triggerAskForDetailsAndStoreFlow(assets: [asset], site: site, supervisor: supervisor) { _ in
                    self?.askForPermissionsIfNeededAndStartNewSession(site: site, supervisor: supervisor)
                }
            case let .failure(error):
                self?.alert = .init(title: "Error", message: "Error happened while capturing an image. \n Details: \(error)", buttons: [.init(title: "Ok", style: .default, action: nil)])
            }
        }
    }
}
