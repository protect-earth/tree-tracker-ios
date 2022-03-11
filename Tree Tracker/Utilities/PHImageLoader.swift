import Photos
import UIKit

final class PHImageLoader: ImageLoader {
    let phImageId: String

    var id: String {
        return phImageId
    }

    private var assetManager = PHAssetManager()
    private lazy var manager: PHCachingImageManager = CurrentEnvironment.photosCachingManager

    init(phImageId: String) {
        self.phImageId = phImageId
    }

    func loadThumbnail(completion: @escaping (UIImage?) -> Void) {
        guard let asset = assetManager.findAssets(for: [phImageId]).first else {
            completion(nil)
            return
        }

        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat

        manager.allowsCachingHighQualityImages = false
        manager.requestImage(
            for: asset,
            targetSize: thumbnailSize,
            contentMode: .aspectFit,
            options: options) { image, info in
            completion(image)
        }
    }

    func loadHighQualityImage(completion: @escaping (UIImage?) -> Void) {
        guard let asset = assetManager.findAssets(for: [phImageId]).first else {
            completion(nil)
            return
        }

        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat

        manager.allowsCachingHighQualityImages = false
        manager.requestImage(
            for: asset,
            targetSize: highQualitySize,
            contentMode: .aspectFit,
            options: options) { image, info in
            completion(image)
        }
    }
    
    func loadUploadImage(completion: @escaping (UIImage?) -> Void) {
        guard let asset = assetManager.findAssets(for: [phImageId]).first else {
            completion(nil)
            return
        }

        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = false
        options.resizeMode = .fast
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat

        manager.allowsCachingHighQualityImages = false
        manager.requestImage(
            for: asset,
            targetSize: uploadSize,
            contentMode: .aspectFit,
            options: options) { image, info in
            completion(image)
        }
    }

    static func == (lhs: PHImageLoader, rhs: PHImageLoader) -> Bool {
        return lhs.phImageId == rhs.phImageId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(phImageId)
    }
}
