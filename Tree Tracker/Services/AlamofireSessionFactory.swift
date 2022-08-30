import Foundation
import Alamofire

protocol AlamofireSessionFactory {
    func get() -> Session
    func baseUrl(adding: String) -> URL
    func getSitesUrl() -> URL
    func getSpeciesUrl() -> URL
    func getSupervisorUrl() -> URL
}
