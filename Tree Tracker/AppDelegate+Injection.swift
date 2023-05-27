import Resolver
import Photos
import UIKit
import AWSS3

extension Resolver: ResolverRegistering {
    
    static let integrationTest = Resolver(child: main)
    
    public static func registerAllServices() {
        // register all components as singletons for lifetime of application
        // defaultScope = .application
        Resolver.defaultScope = .application
        
        // MARK: Base services
        register { Logger(output: .print) }.implements(Logging.self)
        register { Database(logger: resolve()) }
        register { Defaults() }
        register { GRDBImageCache(logger: resolve()) }
        register { UIScreenLockManager() }
        register { PHCachingImageManager() }
        register { RecentSpeciesManager(defaults: resolve(), strategy: .todayUsedSpecies) }
        register { AWSS3Configuration(accessKey: Secrets.awsAccessKey, secretKey: Secrets.awsSecretKey, region: .EUWest1) }
        
        // MARK: Services
        register { ProtectEarthSessionFactory(baseUrl: Constants.Http.protectEarthApiBaseUrl,
                                              apiVersion: Constants.Http.protectEarthApiVersion,
                                              authToken: Secrets.protectEarthApiToken,
                                              httpRequestTimeoutSeconds: Constants.Http.requestTimeoutSeconds,
                                              httpWaitsForConnectivity: true,
                                              httpRetryDelaySeconds: Constants.Http.requestRetryDelaySeconds,
                                              httpRetryLimit: Constants.Http.requestRetryLimit) as AlamofireSessionFactory }
        register { ProtectEarthSupervisorService() as SupervisorService }
        register { ProtectEarthSiteService() as SiteService }
        register { ProtectEarthSpeciesService() as SpeciesService }
        register { ProtectEarthTreeService() as TreeService }
        
        // MARK: Controllers
        register { SitesController() }
        register { SpeciesController() }
        register { SupervisorsController() }
        register { SettingsController(style: UITableView.Style.grouped) }
        
        if CommandLine.arguments.contains("--integration-test") {
            Resolver.root = Resolver.integrationTest
        }
    }
}
