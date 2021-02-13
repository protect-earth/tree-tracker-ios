import Foundation
import Photos
import UIKit

protocol AssetManaging {
    func findAssets(for ids: [String]) -> [PHAsset]
    func save(image: UIImage, location: CLLocation?, completion: @escaping (Result<PHAsset, PHPhotoLibrarySaveImageError>) -> Void)
}

struct PHAssetManager: AssetManaging {
    func findAssets(for ids: [String]) -> [PHAsset] {
        let options = PHFetchOptions()
        options.wantsIncrementalChangeDetails = false

        let results = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: options)

        var assets = [PHAsset]()
        results.enumerateObjects{ asset, _, _ in
            assets.append(asset)
        }

        return assets
    }

    func save(image: UIImage, location: CLLocation?, completion: @escaping (Result<PHAsset, PHPhotoLibrarySaveImageError>) -> Void) {
        PHPhotoLibrary.shared().save(image: image, location: location, completion: completion)
    }
}
