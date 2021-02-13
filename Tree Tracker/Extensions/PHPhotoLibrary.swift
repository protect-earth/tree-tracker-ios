import Photos
import UIKit

enum PHPhotoLibrarySaveImageError: Error {
    case couldntSaveImageToAlbum(innerError: Error)
    case couldntGetLocalIdentifierForAssetRequest
    case couldntGetAssetForIdentifier
}

extension PHPhotoLibrary {
    func save(image: UIImage, location: CLLocation?, completion: @escaping (Result<PHAsset, PHPhotoLibrarySaveImageError>) -> Void) {
        guard let data = image.jpegData(compressionQuality: 1.0) else { return }

        var placeholder: PHObjectPlaceholder?

        performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: data, options: nil)
            request.location = location
            placeholder = request.placeholderForCreatedAsset
        } completionHandler: { success, error in
            if let error = error {
                completion(.failure(.couldntSaveImageToAlbum(innerError: error)))
                return
            }

            guard let identifier = placeholder?.localIdentifier else {
                completion(.failure(.couldntGetLocalIdentifierForAssetRequest))
                return
            }

            guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: .none).firstObject else {
                completion(.failure(.couldntGetAssetForIdentifier))
                return
            }

            completion(.success(asset))
        }
    }
}
