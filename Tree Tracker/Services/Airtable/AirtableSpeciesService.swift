import Foundation
import Resolver
import Alamofire

class AirtableSpeciesService: SpeciesService {
    
    @Injected private var database: Database
    @Injected private var sessionFactory: AlamofireSessionFactory
    
    // MARK: data publisher
    // See https://swiftsenpai.com/swift/define-protocol-with-published-property-wrapper/
    @Published var species: [Species] = []
    var speciesPublisher: Published<[Species]>.Publisher { $species }
    
    // MARK: business logic
    init() {
        self.sync() { _ in } // fire and forget
    }
    
    // Synchronise local cache with remote datastore
    func sync(completion: @escaping (Result<Bool, ProtectEarthError>) -> Void) {
        let request = getSession().request(sessionFactory.getSpeciesUrl(),
                                           method: .get,
                                           encoding: URLEncoding.queryString)

        request.validate().responseDecodable(decoder: JSONDecoder._iso8601ms) { [weak self] (response: DataResponse<Paginated<AirtableSpecies>, AFError>) in
            // TODO: Handle multiple pages (where number of species > 100)
            switch response.result {
            case .success:
                do {
                    let result = try response.result.get()
                    self?.species.removeAll()
                    result.records.forEach { airtableSpecies in
                        self?.species.append(airtableSpecies.toSpecies())
                    }
                    self?.database.replace(self!.species) {
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
    
    // Return species from local cache
    func fetchAll(completion: @escaping (Result<[Species], ProtectEarthError>) -> Void) {
        database.fetchAll(Species.self) { [weak self] species in
            self?.species.removeAll()
            species.forEach() { self?.species.append($0) }
            completion(Result.success(self!.species))
        }
    }
    
    // Add a species to remote and trigger a sync to update local cache
    func addSpecies(name: String, completion: @escaping (Result<Species, ProtectEarthError>) -> Void) {
        fatalError("addSpecies(name:, completion:) has not been implemented")
    }
    
    private func getSession() -> Session {
        sessionFactory.get()
    }
    
}


