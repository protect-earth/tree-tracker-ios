import Foundation
import Resolver
import Alamofire

class ProtectEarthSupervisorService: SupervisorService {
    
    @Injected private var database: Database
    @Injected private var sessionFactory: AlamofireSessionFactory
    
    // MARK: data publisher
    // See https://swiftsenpai.com/swift/define-protocol-with-published-property-wrapper/
    @Published var supervisors: [Supervisor] = []
    var supervisorPublisher: Published<[Supervisor]>.Publisher { $supervisors }
    
    // MARK: business logic
    init() {
        self.sync() { _ in } // fire and forget
    }
    
    // Synchronise local cache with remote datastore
    func sync(completion: @escaping (Result<Bool, ProtectEarthError>) -> Void) {
        let request = getSession().request(sessionFactory.getSupervisorUrl(),
                                           method: .get,
                                           encoding: URLEncoding.queryString)

        request.validate().responseDecodable(decoder: JSONDecoder._iso8601ms) { [weak self] (response: DataResponse<[ProtectEarthSupervisor], AFError>) in
            guard let self = self else { return }
            switch response.result {
                case .success:
                    do {
                        let result = try response.result.get()
                        self.supervisors.removeAll()
                        result.forEach { record in
                            self.supervisors.append(record.toSupervisor())
                        }
                        self.database.replace(self.supervisors) {
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
    
    // Return data from local cache, adding to buffer
    func fetchAll(completion: @escaping (Result<[Supervisor], ProtectEarthError>) -> Void) {
        database.fetchAll(Supervisor.self) { [weak self] records in
            guard let self = self else { return }
            self.supervisors.removeAll()
            records.forEach() { self.supervisors.append($0) }
            completion(Result.success(self.supervisors))
        }
    }
    
    // Add a record to remote and trigger a sync to update local cache
    func addSupervisor(name: String, completion: @escaping (Result<Supervisor, ProtectEarthError>) -> Void) {
        fatalError("addSupervisor(name:, completion:) has not been implemented")
    }
    
    private func getSession() -> Session {
        sessionFactory.get()
    }
    
}
