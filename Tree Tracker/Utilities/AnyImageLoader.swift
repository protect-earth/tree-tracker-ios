import Foundation
import UIKit

final class AnyImageLoader: Hashable, ImageLoader {
    var id: String {
        return imageLoader.id
    }

    private let imageLoader: ImageLoader

    init(imageLoader: ImageLoader) {
        self.imageLoader = imageLoader
    }

    static func == (lhs: AnyImageLoader, rhs: AnyImageLoader) -> Bool {
        return lhs.imageLoader.id == rhs.imageLoader.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(imageLoader.id)
    }

    func loadThumbnail(completion: @escaping (UIImage?) -> Void) {
        imageLoader.loadThumbnail(completion: completion)
    }

    func loadHighQualityImage(completion: @escaping (UIImage?) -> Void) {
        imageLoader.loadHighQualityImage(completion: completion)
    }
}
