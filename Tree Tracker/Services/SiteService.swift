import Foundation
import Alamofire

protocol SiteService {
    // See https://swiftsenpai.com/swift/define-protocol-with-published-property-wrapper/
    var sitesPublisher: Published<[Site]>.Publisher { get }
    func fetchAll(completion: @escaping (Result<[Site], DataAccessError>) -> Void)
    func addSite(name: String, completion: @escaping (Result<Site, DataAccessError>) -> Void)
    func sync(completion: @escaping (Result<Bool, DataAccessError>) -> Void)
}