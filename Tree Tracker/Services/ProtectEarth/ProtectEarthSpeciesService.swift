import Foundation
import Resolver
import Alamofire

class ProtectEarthSpeciesService: SpeciesService {

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
    
    func fetchAll(completion: @escaping (Result<[Species], ProtectEarthError>) -> Void) {
        database.fetchAll(Species.self) { [weak self] records in
            guard let self = self else { return }
            self.species.removeAll()
            records.forEach() { self.species.append($0) }
            completion(Result.success(self.species))
        }
    }
    
    func sync(completion: @escaping (Result<Bool, ProtectEarthError>) -> Void) {
        let request = getSession().request(sessionFactory.getSpeciesUrl(),
                                           method: .get,
                                           encoding: URLEncoding.queryString)
        
        request.validate().responseDecodable(decoder: JSONDecoder._iso8601ms) { [weak self] (response: DataResponse<[ProtectEarthSpecies], AFError>) in
            guard let self = self else { return }
            switch response.result {
                case .success:
                    do {
                        let result = try response.result.get()
                        self.species.removeAll()
                        result.forEach { record in
                            self.species.append(record.toSpecies())
                        }
                        self.database.replace(self.species) {
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
    
    func addSpecies(name: String, completion: @escaping (Result<Species, ProtectEarthError>) -> Void) {
        fatalError("addSpecies(name:, completion:) has not been implemented")
    }
    
    private func getSession() -> Session {
        sessionFactory.get()
    }
    
}
