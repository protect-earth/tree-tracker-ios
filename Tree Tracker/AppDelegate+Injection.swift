import Resolver
import Photos
import UIKit

extension Resolver: ResolverRegistering {
    
    static let mock = Resolver(child: main)
    
    public static func registerAllServices() {
        // register all components as singletons for lifetime of application
        // defaultScope = .application
        
        register { Logger(output: .print) }.implements(Logging.self)
        register { Database(logger: resolve()) }
        register { AlamofireApi(logger: resolve()) }.implements(Api.self)
        register { Defaults() }
        register { GRDBImageCache(logger: resolve()) }
        register { UIScreenLockManager() }
        register { PHCachingImageManager() }
        register { RecentSpeciesManager(defaults: resolve(), strategy: .todayUsedSpecies) }
        register { AirtableSiteService() as SiteService }
        register { SitesController() }
        register { SettingsController(style: UITableView.Style.grouped) }
        
        // test component registrations
        mock.register { MockApi() as Api }
        
        if CommandLine.arguments.contains("--mock-server") {
            Resolver.root = Resolver.mock
        }
    }
}
