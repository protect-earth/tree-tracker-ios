import Foundation
import Alamofire

class CloudinarySessionFactory {
    
    private var session: Session?
    private var httpRequestTimeoutSeconds: TimeInterval
    private var httpWaitsForConnectivity: Bool
    private var httpRetryDelaySeconds: Int
    private var httpRetryLimit: Int
    
    init(httpRequestTimeoutSeconds: TimeInterval,
         httpWaitsForConnectivity: Bool,
         httpRetryDelaySeconds: Int,
         httpRetryLimit: Int) {
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
            
            let interceptor = Interceptor(adapter: NoOpAdapter(),
                                          retrier: RetryingRequestInterceptor(retryDelaySecs: httpRetryDelaySeconds,
                                                                              maxRetries: httpRetryLimit))
            
            session = Session(configuration: sessionConfig,
                              interceptor: interceptor)
        }
        return session!
    }
}

private class NoOpAdapter: RequestAdapter {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        completion(.success(urlRequest))
    }
}
