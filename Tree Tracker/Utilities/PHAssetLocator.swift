import Foundation
import Photos

struct PHAssetLocator {
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
}
