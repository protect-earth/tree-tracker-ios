import Foundation
import class UIKit.UIImage

protocol ImageCaching {
    func add(image: UIImage, for url: URL)
    func removeImage(for url: URL)
    func image(for url: URL) -> UIImage?
}
