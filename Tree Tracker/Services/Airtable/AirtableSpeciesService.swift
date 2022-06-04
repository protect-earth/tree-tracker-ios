import Foundation
import Resolver
import Alamofire

class AirtableSpeciesService: SpeciesService {
    
    @Injected private var database: Database
    
    // MARK: data publisher
    // See https://swiftsenpai.com/swift/define-protocol-with-published-property-wrapper/
    @Published var species: [Species] = []
    var speciesPublisher: Published<[Species]>.Publisher { $species }
        
    // MARK: private variables
    private var session: Session
    private var interceptor: RequestInterceptor
    private var speciesUrl: URL
    
    private var headers = HTTPHeaders(["Authorization": "Bearer \(Constants.Airtable.apiKey)"])
    
    // MARK: business logic
    init() {
        speciesUrl = URL(string: "https://api.airtable.com/v0/\(Constants.Airtable.baseId)")!
        speciesUrl.appendPathComponent(Constants.Airtable.speciesTable)
        
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
        let request = session.request(speciesUrl,
                                      method: .get,
                                      parameters: nil,
                                      encoding: URLEncoding.queryString,
                                      headers: headers,
                                      interceptor: interceptor,
                                      requestModifier: nil)

        request.validate().responseDecodable(decoder: JSONDecoder._iso8601ms) { [weak self] (response: DataResponse<Paginated<AirtableSpecies>, AFError>) in
            // TODO: Handle multiple pages (where number of sites > 100)
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
                completion(.failure(DataAccessError.remoteError(errorCode: response.error!.responseCode!,
                                                                errorMessage: (response.error!.errorDescription!))))
            }
        }
    }
    
    // Return species from local cache
    func fetchAll(completion: @escaping (Result<[Species], DataAccessError>) -> Void) {
        database.fetchAll(Species.self) { [weak self] species in
            self?.species.removeAll()
            species.forEach() { self?.species.append($0) }
            completion(Result.success(self!.species))
        }
    }
    
    // Add a species to remote and trigger a sync to update local cache
    func addSpecies(name: String, completion: @escaping (Result<Species, DataAccessError>) -> Void) {
        fatalError("addSpecies(name:, completion:) has not been implemented")
    }
    
}


