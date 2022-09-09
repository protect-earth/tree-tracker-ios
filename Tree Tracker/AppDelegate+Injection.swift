import Resolver
import Photos
import UIKit

extension Resolver: ResolverRegistering {
    
    static let mock = Resolver(child: main)
    static let integrationTest = Resolver(child: main)
    static let protectEarthApi = Resolver(child: integrationTest)
    static let airtable = Resolver(child: main)
    
    public static func registerAllServices() {
        // register all components as singletons for lifetime of application
        // defaultScope = .application
        Resolver.defaultScope = .application
        
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
        //TODO: remove all Airtable services
        airtable.register { AirtableSessionFactory(airtableBaseId: Constants.Airtable.baseId,
                                                   airtableApiKey: Constants.Airtable.apiKey,
                                                   httpRequestTimeoutSeconds: Constants.Http.requestTimeoutSeconds,
                                                   httpWaitsForConnectivity: true,
                                                   httpRetryDelaySeconds: Constants.Http.requestRetryDelaySeconds,
                                                   httpRetryLimit: Constants.Http.requestRetryLimit) as AlamofireSessionFactory }
        
        airtable.register { AirtableSiteService() as SiteService }
        airtable.register { AirtableSpeciesService() as SpeciesService }
        airtable.register { AirtableSupervisorService() as SupervisorService }
        
        // MARK: Protect Earth API specific services
        protectEarthApi.register { ProtectEarthSessionFactory(baseUrl: Constants.Http.protectEarthApiBaseUrl,
                                                              apiVersion: Constants.Http.protectEarthApiVersion,
                                                              authToken: Secrets.protectEarthApiToken,
                                                              httpRequestTimeoutSeconds: Constants.Http.requestTimeoutSeconds,
                                                              httpWaitsForConnectivity: true,
                                                              httpRetryDelaySeconds: Constants.Http.requestRetryDelaySeconds,
                                                              httpRetryLimit: Constants.Http.requestRetryLimit) as AlamofireSessionFactory }
        protectEarthApi.register { ProtectEarthSupervisorService() as SupervisorService }
        protectEarthApi.register { ProtectEarthSiteService() as SiteService }
        protectEarthApi.register { ProtectEarthSpeciesService() as SpeciesService }
        protectEarthApi.register { ProtectEarthTreeService() as TreeService }
        //TODO: sort out injection for prefixKey and naming
        protectEarthApi.register { CloudinarySessionFactory(httpRequestTimeoutSeconds: Constants.Http.requestTimeoutSeconds,
                                                            httpWaitsForConnectivity: true,
                                                            httpRetryDelaySeconds: Constants.Http.requestRetryDelaySeconds,
                                                            httpRetryLimit: Constants.Http.requestRetryLimit) }
        
        // MARK: Controllers
        register { SitesController() }
        register { SpeciesController() }
        register { SupervisorsController() }
        register { SettingsController(style: UITableView.Style.grouped) }
        
        // MARK: test component registrations
        mock.register { MockApi() as Api }
        
        integrationTest.register { AirtableSessionFactory(airtableBaseId: Secrets.testAirtableBaseId,
                                                          airtableApiKey: Secrets.testAirtableApiKey,
                                                          airtableTablePrefix: Secrets.testAirtableTableNamePrefix,
                                                          httpRequestTimeoutSeconds: Constants.Http.requestTimeoutSeconds,
                                                          httpWaitsForConnectivity: true,
                                                          httpRetryDelaySeconds: Constants.Http.requestRetryDelaySeconds,
                                                          httpRetryLimit: Constants.Http.requestRetryLimit) as AlamofireSessionFactory }
        
        if CommandLine.arguments.contains("--mock-server") {
            Resolver.root = Resolver.mock
        }
        
        if CommandLine.arguments.contains("--integration-test") {
            Resolver.root = Resolver.integrationTest
        }
        
        if CommandLine.arguments.contains("--airtable") {
            Resolver.root = Resolver.airtable
        }
        
        // default to using Protect Earth API
        Resolver.root = Resolver.protectEarthApi
    }
}
