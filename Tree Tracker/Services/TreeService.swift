import Foundation
import Alamofire

protocol TreeService {
    func publish(tree: LocalTree, progress: @escaping (Double) -> Void, completion: @escaping (Result<Bool, ProtectEarthError>) -> Void)
}
