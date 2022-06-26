import Foundation
import Alamofire
import class UIKit.UIImage

protocol Api {
    func species(offset: String?, completion: @escaping (Result<Paginated<AirtableSpecies>, AFError>) -> Void)
    func sites(offset: String?, completion: @escaping (Result<Paginated<AirtableSite>, AFError>) -> Void)
    func supervisors(offset: String?, completion: @escaping (Result<Paginated<AirtableSupervisor>, AFError>) -> Void)
    func upload(tree: LocalTree, progress: @escaping (Double) -> Void, completion: @escaping (Result<AirtableTree, AFError>) -> Void) -> Cancellable
    func loadImage(url: String, completion: @escaping (UIImage?) -> Void)
    func addSite(name: String, completion: @escaping (Result<AirtableSite, AFError>) -> Void)
}
