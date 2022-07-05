import Foundation
import Resolver
import Alamofire

class ProtectEarthSiteService: SiteService {

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
    
    func fetchAll(completion: @escaping (Result<[Site], DataAccessError>) -> Void) {
        database.fetchAll(Site.self) { [weak self] records in
            guard let self = self else { return }
            self.sites.removeAll()
            records.forEach() { self.sites.append($0) }
            completion(Result.success(self.sites))
        }
    }
    
    func sync(completion: @escaping (Result<Bool, DataAccessError>) -> Void) {
        let request = getSession().request(sessionFactory.getSitesUrl(),
                                           method: .get,
                                           encoding: URLEncoding.queryString)
        
        request.validate().responseDecodable(decoder: JSONDecoder._iso8601ms) { [weak self] (response: DataResponse<[ProtectEarthSite], AFError>) in
            guard let self = self else { return }
            switch response.result {
                case .success:
                    do {
                        let result = try response.result.get()
                        self.sites.removeAll()
                        result.forEach { record in
                            self.sites.append(record.toSite())
                        }
                        self.database.replace(self.sites) {
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
    
    func addSite(name: String, completion: @escaping (Result<Bool, DataAccessError>) -> Void) {
        fatalError("addSite(name:, completion:) has not been implemented")
    }
    
    private func getSession() -> Session {
        sessionFactory.get()
    }
    
}
