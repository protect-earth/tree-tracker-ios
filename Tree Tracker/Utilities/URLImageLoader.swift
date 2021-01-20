import UIKit

final class URLImageLoader: ImageLoader {
    let url: String

    var id: String {
        return url
    }

    private let api: Api

    init(api: Api = CurrentEnvironment.api, url: String) {
        self.api = api
        self.url = url
    }

    func loadThumbnail(completion: @escaping (UIImage?) -> Void) {
        api.loadImage(url: url) { [weak self] image in
            guard let self = self, let image = image else {
                completion(nil)
                return
            }

            let aspectRatio = image.size.width / image.size.height
            let newSize = CGSize(width: self.thumbnailSize.width, height: self.thumbnailSize.width / aspectRatio)
            completion(image.resize(to: newSize))
        }
    }

    func loadHighQualityImage(completion: @escaping (UIImage?) -> Void) {
        api.loadImage(url: url) { image in
            completion(image)
        }
    }

    static func == (lhs: URLImageLoader, rhs: URLImageLoader) -> Bool {
        return lhs.url == rhs.url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}
