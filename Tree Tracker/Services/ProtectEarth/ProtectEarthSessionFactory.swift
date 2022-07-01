import Foundation
import Alamofire

/*
 Provides request interception, including retry and authentication, for Protect Earth API requests
 */
class ProtectEarthSessionFactory: AlamofireSessionFactory {
    
    private var session: Session?
    private var baseUrl: String
    private var apiVersion: String
    private var authToken: String
    private var httpRequestTimeoutSeconds: TimeInterval
    private var httpWaitsForConnectivity: Bool
    private var httpRetryDelaySeconds: Int
    private var httpRetryLimit: Int
    
    init(baseUrl: String,
         apiVersion: String,
         authToken: String,
         httpRequestTimeoutSeconds: TimeInterval,
         httpWaitsForConnectivity: Bool,
         httpRetryDelaySeconds: Int,
         httpRetryLimit: Int) {
        self.baseUrl = baseUrl
        self.apiVersion = apiVersion
        self.authToken = authToken
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
            
            let interceptor = Interceptor(adapter: BearerTokenAuthenticationAdapter(authToken),
                                          retrier: RetryingRequestInterceptor(retryDelaySecs: httpRetryDelaySeconds,
                                                                              maxRetries: httpRetryLimit))
            
            session = Session(configuration: sessionConfig,
                              interceptor: interceptor)
        }
        return session!
    }
    
    func baseUrl(adding: String) -> URL {
        var result = URL(string: "https://\(baseUrl)/\(apiVersion)/")!
        result.appendPathComponent(adding)
        return result
    }
    
    func getSitesUrl() -> URL {
        return baseUrl(adding: "sites")
    }
    
    func getSpeciesUrl() -> URL {
        return baseUrl(adding: "species")
    }
    
    func getSupervisorUrl() -> URL {
        return baseUrl(adding: "supervisors")
    }
    
}
