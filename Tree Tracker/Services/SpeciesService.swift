import Foundation
import Alamofire

protocol SpeciesService {
    // See https://swiftsenpai.com/swift/define-protocol-with-published-property-wrapper/
    var speciesPublisher: Published<[Species]>.Publisher { get }
    func fetchAll(completion: @escaping (Result<[Species], ProtectEarthError>) -> Void)
    func addSpecies(name: String, completion: @escaping (Result<Species, ProtectEarthError>) -> Void)
    func sync(completion: @escaping (Result<Bool, ProtectEarthError>) -> Void)
}
