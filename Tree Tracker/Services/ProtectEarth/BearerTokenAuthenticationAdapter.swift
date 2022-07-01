import Foundation
import Alamofire

class BearerTokenAuthenticationAdapter: RequestAdapter {
    
    private var token: String
    
    init(_ token: String) {
        self.token = token
    }
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        urlRequest.headers.add(.authorization(bearerToken: token))
        completion(.success(urlRequest))
    }
    
}
