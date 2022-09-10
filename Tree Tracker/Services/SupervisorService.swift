import Foundation
import Alamofire

protocol SupervisorService {
    // See https://swiftsenpai.com/swift/define-protocol-with-published-property-wrapper/
    var supervisorPublisher: Published<[Supervisor]>.Publisher { get }
    func fetchAll(completion: @escaping (Result<[Supervisor], ProtectEarthError>) -> Void)
    func addSupervisor(name: String, completion: @escaping (Result<Supervisor, ProtectEarthError>) -> Void)
    func sync(completion: @escaping (Result<Bool, ProtectEarthError>) -> Void)
}
