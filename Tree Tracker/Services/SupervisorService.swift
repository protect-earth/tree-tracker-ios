import Foundation
import Alamofire

protocol SupervisorService {
    // See https://swiftsenpai.com/swift/define-protocol-with-published-property-wrapper/
    var supervisorPublisher: Published<[Supervisor]>.Publisher { get }
    func fetchAll(completion: @escaping (Result<[Supervisor], DataAccessError>) -> Void)
    func addSupervisor(name: String, completion: @escaping (Result<Supervisor, DataAccessError>) -> Void)
    func sync(completion: @escaping (Result<Bool, DataAccessError>) -> Void)
}
