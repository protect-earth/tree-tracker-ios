import Resolver
import Photos
import UIKit

extension Resolver: ResolverRegistering {
    
    static let mock = Resolver(child: main)
    
    public static func registerAllServices() {
        // register all components as singletons for lifetime of application
        // defaultScope = .application
        
        // MARK: Base services
        register { Logger(output: .print) }.implements(Logging.self)
        register { Database(logger: resolve()) }
        register { AlamofireApi(logger: resolve()) }.implements(Api.self)
        register { Defaults() }
        register { GRDBImageCache(logger: resolve()) }
        register { UIScreenLockManager() }
        register { PHCachingImageManager() }
        register { RecentSpeciesManager(defaults: resolve(), strategy: .todayUsedSpecies) }
        
        // MARK: Services
        register { AirtableSiteService() as SiteService }
        register { AirtableSpeciesService() as SpeciesService }
        register { AirtableSupervisorService() as SupervisorService }
        
        // MARK: Controllers
        register { SitesController() }
        register { SpeciesController() }
        register { SupervisorsController() }
        register { SettingsController(style: UITableView.Style.grouped) }
        
        // MARK: test component registrations
        mock.register { MockApi() as Api }
        
        if CommandLine.arguments.contains("--mock-server") {
            Resolver.root = Resolver.mock
        }
    }
}
