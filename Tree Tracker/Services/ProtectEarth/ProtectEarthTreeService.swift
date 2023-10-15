import Foundation
import Resolver
import Alamofire
import UIKit
import RollbarNotifier
import AWSS3

class ProtectEarthTreeService: TreeService {

    @Injected private var database: Database
    @Injected private var awsS3Configuration: AWSS3Configuration
    
    private var completionHolders: [UploadCompletionHolder] = []
    
    // Complete any local tidy up following an upload session
    func tidyUp() {
        database.fetchAll(UploadedTree.self) { [weak self] uploadItems in
            if uploadItems.isNotEmpty {
                let assetManager = PHAssetManager()
                let assetIds = uploadItems.map { $0.phImageId }
                assetManager.deletePhotoAssets(withIds: assetIds) { success, error in
                    if success {
                        print("Deleted \(assetIds.count) photos successfully")
                        Rollbar.infoMessage("Successfully cleared photos from library",
                                           data: ["assetCount": assetIds.count],
                                           context: "PHAssetManager.deletePhotoAssets")
                        
                    } else {
                        print("Photos could not be cleared: \(error!.localizedDescription)")
                        Rollbar.errorError(error!,
                                          data: nil,
                                          context: "PHAssetManager.deletePhotoAssets")
                    }
                    /*
                     If we did not delete photos this is probably because the user declined this option.
                     
                     We should clear down the uploaded items list regardless because otherwise we risk
                     deleting those photos at a later date.
                     
                     A consequence of this is that if the user declines, they will always have to clean up
                     those photos manually, since the app will lose track of them.
                     */
                    self?.database.clearUploadedItems {
                        print("Uploaded items list cleared")
                    }
                }
            }
        }
    }
    
    func publish(tree: LocalTree, progress: @escaping (Double) -> Void, completion: @escaping (Result<Bool, ProtectEarthError>) -> Void) {
        // Step 1: retrieve image at appropriate resolution
        prepareImageForUpload(tree: tree) { [weak self] image in
            
            guard let self = self else { return }
            
            guard let image = image else {
                return completion(.failure(ProtectEarthError.localError(errorCode: 1,
                                                               errorMessage: "Unable to prepare upload image")))
            }
            
            progress(0.1)
            
            // Step 2: Upload the image to storage, with appropriate metadata
            guard let data = image.jpegData(compressionQuality: 0.8) else {
                Rollbar.errorMessage("No jpeg for image, upload will be skipped")
                completion(.failure(.localError(errorCode: 100, errorMessage: "Unable to fetch jpeg image data")))
                return
            }
            let md5 = data.md5()
            
//            guard let plantedDate = tree.createDate else { return }
            guard let coordinates: [String] = tree.coordinates?.components(separatedBy: ", ") else { return }
            
            var latitude = "0"
            var longitude = "0"
            
            if (coordinates.count == 2) {
                latitude = coordinates[0]
                longitude = coordinates[1]
            }
            
            let expression = AWSS3TransferUtilityUploadExpression()
            expression.progressBlock = {(task, taskProgress) in
                progress(0.1 + taskProgress.fractionCompleted * 0.9)
            }
            expression.setValue(tree.createDate?.ISO8601Format(), forRequestHeader: "x-amz-meta-planted-at")
            expression.setValue(tree.supervisor, forRequestHeader: "x-amz-meta-supervisor")
            expression.setValue(latitude, forRequestHeader: "x-amz-meta-latitude")
            expression.setValue(longitude, forRequestHeader: "x-amz-meta-longitude")
            expression.setValue(tree.site, forRequestHeader: "x-amz-meta-site")
            expression.setValue(tree.species, forRequestHeader: "x-amz-meta-species")
            expression.setValue(tree.phImageId, forRequestHeader: "x-amz-meta-phimageid")
            expression.setValue(md5, forRequestHeader: "x-amz-meta-md5")
//            expression.contentMD5 = md5 // uncommenting this leads to a HTTP 400 error

            let transferUtility = AWSS3TransferUtility.default()
            transferUtility.shouldRemoveCompletedTasks = true
            
            let completionHolder = UploadCompletionHolder(tree: tree, database: self.database, completion: completion)
            self.completionHolders.append(completionHolder)
            
            transferUtility.uploadData(data,
                                       bucket: Secrets.awsBucketName,
                                       key: "\(Secrets.awsBucketPrefix)/\(tree.treeId)",
                                       contentType: "image/jpeg",
                                       expression: expression,
                                       completionHandler: completionHolder.completionHandler
            )
            .continueWith { (task) -> AnyObject? in
                // stuff we want to do once the task is *STARTED*
                return nil
            }
        }
    }
    
    private func prepareImageForUpload(tree: LocalTree, completion: @escaping (UIImage?) -> Void) {
        let imageLoader = PHImageLoader(phImageId: tree.phImageId)
        imageLoader.loadUploadImage(completion: completion)
    }
    
}
