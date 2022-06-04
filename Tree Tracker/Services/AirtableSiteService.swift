import Foundation
import Resolver
import Alamofire

class AirtableSiteService: SiteService {
    
    @Injected var database: Database
    
    // MARK: data publisher
    // See https://swiftsenpai.com/swift/define-protocol-with-published-property-wrapper/
    @Published var sites: [Site] = []
    var sitesPublisher: Published<[Site]>.Publisher { $sites }
        
    // MARK: private variables
    private var session: Session
    private var interceptor: RequestInterceptor
    private var sitesUrl: URL
    
    private var headers = HTTPHeaders(["Authorization": "Bearer \(Constants.Airtable.apiKey)"])
    
    // MARK: business logic
    init() {
        sitesUrl = URL(string: "https://api.airtable.com/v0/\(Constants.Airtable.baseId)")!
        sitesUrl.appendPathComponent(Constants.Airtable.sitesTable)
        
        //TODO: consider injecting a session factory
        let sessionConfig = URLSessionConfiguration.af.default
        sessionConfig.timeoutIntervalForRequest = Constants.Http.requestTimeoutSeconds
        sessionConfig.waitsForConnectivity = Constants.Http.requestWaitsForConnectivity
        
        interceptor = RetryingRequestInterceptor(retryDelaySecs: Constants.Http.requestRetryDelaySeconds,
                                                 maxRetries: Constants.Http.requestRetryLimit)
        
        self.session = Session(configuration: sessionConfig,
                               interceptor: interceptor)
        
        self.sync() {_ in} // fire and forget
    }
    
    // Synchronise local cache with remote datastore
    func sync(completion: @escaping (Result<Bool, DataAccessError>) -> Void) {
        let request = session.request(sitesUrl,
                                      method: .get,
                                      parameters: nil,
                                      encoding: URLEncoding.queryString,
                                      headers: headers,
                                      interceptor: interceptor,
                                      requestModifier: nil)

        request.validate().responseDecodable(decoder: JSONDecoder._iso8601ms) { [weak self] (response: DataResponse<Paginated<AirtableSite>, AFError>) in
            // TODO: Handle multiple pages (where number of sites > 100)
            switch response.result {
            case .success:
                do {
                    let result = try response.result.get()
                    self?.sites.removeAll()
                    result.records.forEach { airtableSite in
                        self?.sites.append(airtableSite.toSite())
                    }
                    self?.database.replace(self!.sites) {
                        completion(.success(true))
                    }
                } catch {
                    print("Unexpected error: \(error).")
                }
            case .failure:
                completion(.failure(DataAccessError.remoteError(errorCode: response.error!.responseCode!,
                                                                errorMessage: (response.error!.errorDescription!))))
            }
        }
    }
    
    // Return sites from local cache
    func fetchAll(completion: @escaping (Result<[Site], DataAccessError>) -> Void) {
        database.fetchAll(Site.self) { [weak self] sites in
            completion(Result.success(self!.sites))
        }
    }
    
    // Add a site to remote and trigger a sync to update local cache
    func addSite(name: String, completion: @escaping (Result<Site, DataAccessError>) -> Void) {
        // build struct to represent target JSON body
        let parameters: [String: [String: String]] = [
            "fields": ["Name": name]
        ]
        
        let request = session.request(sitesUrl,
                                      method: .post,
                                      parameters: parameters,
                                      encoder: JSONParameterEncoder.default,
                                      headers: headers,
                                      interceptor: interceptor,
                                      requestModifier: nil)
        
        request.validate().responseDecodable(of: AirtableSite.self, decoder: JSONDecoder._iso8601ms) { response in
                let addedSite = response.value
                
                switch response.result {
                case .success:
                    self.sync() {_ in} // fire and forget
                    completion(.success(addedSite!.toSite()))
                case .failure:
                    completion(.failure(DataAccessError.remoteError(errorCode: response.error!.responseCode!,
                                                                    errorMessage: (response.error!.errorDescription!))))
                }
                
            }
    }
    
}
