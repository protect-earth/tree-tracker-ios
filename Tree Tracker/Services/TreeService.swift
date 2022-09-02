import Foundation
import Alamofire

protocol TreeService {
    func publish(tree: PETree, completion: @escaping (Result<Bool, DataAccessError>) -> Void)
}
