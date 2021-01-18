import Photos
import UIKit

final class PHImageLoader: Hashable {
    let phImageId: String

    private var asset: PHAsset?
    private lazy var manager: PHCachingImageManager = CurrentEnvironment.photosCachingManager

    init(phImageId: String) {
        self.phImageId = phImageId
    }

    func loadThumbnail(completion: @escaping (UIImage?) -> Void) {
        guard let asset = findAsset() else { return }

        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast
        options.isSynchronous = false
        options.deliveryMode = .fastFormat

        manager.allowsCachingHighQualityImages = false
        manager.requestImage(
            for: asset,
            targetSize: CGSize(width: 256.0, height: 256.0),
            contentMode: .aspectFit,
            options: options) { image, info in
            completion(image)
        }
    }

    func loadHighQualityImage(completion: @escaping (UIImage?) -> Void) {
        guard let asset = findAsset() else { return }

        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat

        manager.allowsCachingHighQualityImages = false
        manager.requestImage(
            for: asset,
            targetSize: CGSize(width: 2048.0, height: 2048.0),
            contentMode: .aspectFit,
            options: options) { image, info in
            completion(image)
        }
    }

    private func findAsset() -> PHAsset? {
        let options = PHFetchOptions()
        options.wantsIncrementalChangeDetails = false

        guard let asset = self.asset ?? PHAsset.fetchAssets(withLocalIdentifiers: [phImageId], options: nil).firstObject else { return nil }

        self.asset = asset

        return asset
    }

    static func == (lhs: PHImageLoader, rhs: PHImageLoader) -> Bool {
        return lhs.phImageId == rhs.phImageId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(phImageId)
    }
}
