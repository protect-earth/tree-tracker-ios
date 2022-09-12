import Foundation
import Resolver
import Alamofire

class AirtableSiteService: SiteService {
    
    @Injected private var database: Database
    @Injected private var sessionFactory: AlamofireSessionFactory
    
    // MARK: data publisher
    // See https://swiftsenpai.com/swift/define-protocol-with-published-property-wrapper/
    @Published var sites: [Site] = []
    var sitesPublisher: Published<[Site]>.Publisher { $sites }
    
    // MARK: business logic
    init() {
        self.sync() { _ in } // fire and forget
    }
    
    // Synchronise local cache with remote datastore
    func sync(completion: @escaping (Result<Bool, ProtectEarthError>) -> Void) {
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
                completion(.failure(ProtectEarthError.remoteError(errorCode: response.error!.responseCode!,
                                                                errorMessage: (response.error!.errorDescription!))))
            }
        }
    }
    
    // Return sites from local cache, adding to buffer
    func fetchAll(completion: @escaping (Result<[Site], ProtectEarthError>) -> Void) {
        database.fetchAll(Site.self) { [weak self] sites in
            self?.sites.removeAll()
            sites.forEach() { self?.sites.append($0) }
            completion(Result.success(self!.sites))
        }
    }
    
    private func getSession() -> Session {
        sessionFactory.get()
    }
    
}
