import Foundation
import Alamofire
import class UIKit.UIImage

protocol Api {
    func upload(tree: LocalTree, progress: @escaping (Double) -> Void, completion: @escaping (Result<AirtableTree, AFError>) -> Void) -> Cancellable
    func loadImage(url: String, completion: @escaping (UIImage?) -> Void)
}
