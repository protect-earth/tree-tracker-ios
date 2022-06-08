import Foundation
import Resolver
import Alamofire

class AirtableSiteService: SiteService {
    
    @Injected private var database: Database
    @Injected private var sessionFactory: AirtableSessionFactory
    
    // MARK: data publisher
    // See https://swiftsenpai.com/swift/define-protocol-with-published-property-wrapper/
    @Published var sites: [Site] = []
    var sitesPublisher: Published<[Site]>.Publisher { $sites }
    
    // MARK: business logic
    init() {
        self.sync() { _ in } // fire and forget
    }
    
    // Synchronise local cache with remote datastore
    func sync(completion: @escaping (Result<Bool, DataAccessError>) -> Void) {
        let request = getSession().request(sessionFactory.getSitesUrl(),
                                           method: .get,
                                           encoding: URLEncoding.queryString)

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
    
    // Return sites from local cache, adding to buffer
    func fetchAll(completion: @escaping (Result<[Site], DataAccessError>) -> Void) {
        database.fetchAll(Site.self) { [weak self] sites in
            self?.sites.removeAll()
            sites.forEach() { self?.sites.append($0) }
            completion(Result.success(self!.sites))
        }
    }
    
    // Add a site to remote and trigger a sync to update local cache
    func addSite(name: String, completion: @escaping (Result<Bool, DataAccessError>) -> Void) {
        // build struct to represent target JSON body
        let parameters: [String: [String: String]] = [
            "fields": ["Name": name]
        ]
        
        let request = getSession().request(sessionFactory.getSitesUrl(),
                                           method: .post,
                                           parameters: parameters,
                                           encoder: JSONParameterEncoder.default)
        
        request.validate().responseDecodable(of: AirtableSite.self, decoder: JSONDecoder._iso8601ms) { response in            
            switch response.result {
            case .success:
                self.sync { result in
                    completion(result)
                }
            case .failure:
                completion(.failure(DataAccessError.remoteError(errorCode: response.error!.responseCode!,
                                                                errorMessage: (response.error!.errorDescription!))))
            }
        }
    }
    
    private func getSession() -> Session {
        sessionFactory.get()
    }
    
}
