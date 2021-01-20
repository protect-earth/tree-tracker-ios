import Foundation
import Photos

final class PHAssetLocator: Hashable {
    let phImageId: String

    var asset: PHAsset? {
        findAsset()
    }

    private var cachedAsset: PHAsset?

    init(phImageId: String) {
        self.phImageId = phImageId
    }

    private func findAsset() -> PHAsset? {
        let options = PHFetchOptions()
        options.wantsIncrementalChangeDetails = false

        guard let asset = self.cachedAsset ?? PHAsset.fetchAssets(withLocalIdentifiers: [phImageId], options: options).firstObject else { return nil }

        self.cachedAsset = asset

        return asset
    }

    static func == (lhs: PHAssetLocator, rhs: PHAssetLocator) -> Bool {
        return lhs.phImageId == rhs.phImageId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(phImageId)
    }
}
