import UIKit

protocol ImageLoader {
    var id: String { get }

    func loadThumbnail(completion: @escaping (UIImage?) -> Void)
    func loadHighQualityImage(completion: @escaping (UIImage?) -> Void)
}

extension ImageLoader {
    var thumbnailSize: CGSize { CGSize(width: 256.0, height: 256.0) }
    var highQualitySize: CGSize { CGSize(width: 2048.0, height: 2048.0) }
}
