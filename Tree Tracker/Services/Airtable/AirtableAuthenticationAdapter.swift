import Foundation
import Alamofire

class AirtableAuthenticationAdapter: RequestAdapter {
    
    private var apiKey: String
    
    init(_ apiKey: String) {
        self.apiKey = apiKey
    }
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        urlRequest.headers.add(.authorization(bearerToken: apiKey))
        completion(.success(urlRequest))
    }
    
}
