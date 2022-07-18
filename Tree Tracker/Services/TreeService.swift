import Foundation
import Alamofire

protocol TreeService {
    func publish(tree: LocalTree, completion: @escaping (Result<Bool, DataAccessError>) -> Void)
}
