import Foundation
import Resolver
import Alamofire

class AirtableSupervisorService: SupervisorService {
    
    @Injected private var database: Database
    
    // MARK: data publisher
    // See https://swiftsenpai.com/swift/define-protocol-with-published-property-wrapper/
    @Published var supervisors: [Supervisor] = []
    var supervisorPublisher: Published<[Supervisor]>.Publisher { $supervisors }
        
    // MARK: private variables
    private var session: Session
    private var interceptor: RequestInterceptor
    private var supervisorUrl: URL
    
    private var headers = HTTPHeaders(["Authorization": "Bearer \(Constants.Airtable.apiKey)"])
    
    // MARK: business logic
    init() {
        supervisorUrl = URL(string: "https://api.airtable.com/v0/\(Constants.Airtable.baseId)")!
        supervisorUrl.appendPathComponent(Constants.Airtable.supervisorsTable)
        
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
        let request = session.request(supervisorUrl,
                                      method: .get,
                                      parameters: nil,
                                      encoding: URLEncoding.queryString,
                                      headers: headers,
                                      interceptor: interceptor,
                                      requestModifier: nil)

        request.validate().responseDecodable(decoder: JSONDecoder._iso8601ms) { [weak self] (response: DataResponse<Paginated<AirtableSupervisor>, AFError>) in
            // TODO: Handle multiple pages (where number of entries > 100)
            switch response.result {
            case .success:
                do {
                    let result = try response.result.get()
                    self?.supervisors.removeAll()
                    result.records.forEach { record in
                        self?.supervisors.append(record.toSupervisor())
                    }
                    self?.database.replace(self!.supervisors) {
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
    
    // Return data from local cache
    func fetchAll(completion: @escaping (Result<[Supervisor], DataAccessError>) -> Void) {
        database.fetchAll(Supervisor.self) { [weak self] supervisor in
            completion(Result.success(self!.supervisors))
        }
    }
    
    // Add a record to remote and trigger a sync to update local cache
    func addSupervisor(name: String, completion: @escaping (Result<Supervisor, DataAccessError>) -> Void) {
        fatalError("addSupervisor(name:, completion:) has not been implemented")
    }
    
}
