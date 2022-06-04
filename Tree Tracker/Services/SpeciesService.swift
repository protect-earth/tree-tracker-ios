import Foundation
import Alamofire

protocol SpeciesService {
    // See https://swiftsenpai.com/swift/define-protocol-with-published-property-wrapper/
    var speciesPublisher: Published<[Species]>.Publisher { get }
    func fetchAll(completion: @escaping (Result<[Species], DataAccessError>) -> Void)
    func addSpecies(name: String, completion: @escaping (Result<Species, DataAccessError>) -> Void)
    func sync(completion: @escaping (Result<Bool, DataAccessError>) -> Void)
}
