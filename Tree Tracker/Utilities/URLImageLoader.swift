import Foundation
import class UIKit.UIImage
import struct CoreGraphics.CGSize
import Resolver

fileprivate extension LogCategory {
    static var imageLoader = LogCategory(name: "ImageLoader")
}

final class URLImageLoader: ImageLoader {
    let url: String

    var id: String {
        return url
    }

    @Injected private var api: Api
    
    private let thumbnailsImageCache: ImageCaching
    private let logger: Logging

    init(url: String, thumbnailsImageCache: ImageCaching = CurrentEnvironment.imageCache, logger: Logging = CurrentEnvironment.logger) {
        self.url = url
        self.thumbnailsImageCache = thumbnailsImageCache
        self.logger = logger
    }

    func loadThumbnail(completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, let url = URL(string: self.url) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            if let image = self.thumbnailsImageCache.image(for: url) {
                DispatchQueue.main.async {
                    self.logger.log(.imageLoader, "Image from cache for url: \(url)")
                    completion(image)
                }

                return
            }

            self.api.loadImage(url: self.url) { [weak self] image in
                guard let self = self, let image = image else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }

                DispatchQueue.global(qos: .userInitiated).async {
                    self.logger.log(.imageLoader, "Image from the webz for url: \(self.url)")
                    self.thumbnailsImageCache.add(image: image, for: url)
                    self.resize(image: image, completion: completion)
                }
            }
        }
    }

    private func resize(image: UIImage, completion: @escaping (UIImage?) -> Void) {
        let aspectRatio = image.size.width / image.size.height
        let newSize = CGSize(width: self.thumbnailSize.width, height: self.thumbnailSize.width / aspectRatio)
        let resizedImage = image.resize(to: newSize)
        DispatchQueue.main.async {
            completion(resizedImage)
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
