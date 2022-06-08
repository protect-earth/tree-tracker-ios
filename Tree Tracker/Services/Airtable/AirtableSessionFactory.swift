import Foundation
import Alamofire

/*
 Provides request interception, including retry and authentication, for Airtable requests
 */
class AirtableSessionFactory {
    
    private var session: Session?
    private var airtableBaseId: String
    private var airtableApiKey: String
    private var httpRequestTimeoutSeconds: TimeInterval
    private var httpWaitsForConnectivity: Bool
    private var httpRetryDelaySeconds: Int
    private var httpRetryLimit: Int
    private var airtableTablePrefix: String
    
    init(airtableBaseId: String,
         airtableApiKey: String,
         airtableTablePrefix: String = "",
         httpRequestTimeoutSeconds: TimeInterval,
         httpWaitsForConnectivity: Bool,
         httpRetryDelaySeconds: Int,
         httpRetryLimit: Int) {
        self.airtableBaseId = airtableBaseId
        self.airtableApiKey = airtableApiKey
        self.airtableTablePrefix = airtableTablePrefix
        self.httpRequestTimeoutSeconds = httpRequestTimeoutSeconds
        self.httpWaitsForConnectivity = httpWaitsForConnectivity
        self.httpRetryDelaySeconds = httpRetryDelaySeconds
        self.httpRetryLimit = httpRetryLimit
    }
    
    func get() -> Session {
        if session == nil {
            let sessionConfig = URLSessionConfiguration.af.default
            sessionConfig.timeoutIntervalForRequest = httpRequestTimeoutSeconds
            sessionConfig.waitsForConnectivity = httpWaitsForConnectivity
            
            let interceptor = Interceptor(adapter: AirtableAuthenticationAdapter(airtableApiKey),
                                          retrier: RetryingRequestInterceptor(retryDelaySecs: httpRetryDelaySeconds,
                                                                              maxRetries: httpRetryLimit))
            
            session = Session(configuration: sessionConfig,
                              interceptor: interceptor)
        }
        return session!
    }
    
    func baseUrl(adding: String) -> URL {
        var result = URL(string: "https://api.airtable.com/v0/\(airtableBaseId)")!
        result.appendPathComponent(adding)
        return result
    }
    
    func getSitesUrl() -> URL {
        return baseUrl(adding: "\(airtableTablePrefix)\(Constants.Airtable.sitesTable)")
    }
    
    func getSpeciesUrl() -> URL {
        return baseUrl(adding: "\(airtableTablePrefix)\(Constants.Airtable.speciesTable)")
    }
    
    func getSupervisorUrl() -> URL {
        return baseUrl(adding: "\(airtableTablePrefix)\(Constants.Airtable.supervisorsTable)")
    }
    
}
