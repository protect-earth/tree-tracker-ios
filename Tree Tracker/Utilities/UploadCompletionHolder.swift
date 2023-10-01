import Foundation
import AWSS3
import RollbarNotifier

class UploadCompletionHolder {
    
    @objc var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
    
    private var database: Database
    private var tree: LocalTree
    
    init(tree: LocalTree, database: Database, completion: @escaping (Result<Bool, ProtectEarthError>) -> Void) {
        
        self.database = database
        self.tree = tree
        
        self.completionHandler = { (task, error) -> Void in
            if let error = error {
                let responseCode = task.response?.statusCode.description ?? "???"
                completion(.failure(.remoteError(errorCode: 243, errorMessage: "Error in S3 upload - [\(responseCode)] \(error.localizedDescription)")))
            }
            else if task.status != .completed {
                completion(.failure(.remoteError(errorCode: 245, errorMessage: "Unknown S3 error")))
            }
            else {
                // save uploaded tree, remove from queue and post rollbar success message
                let upload = UploadedTree.fromTree(tree)
                database.save([upload])
                database.remove(tree: tree) {
                    Rollbar.infoMessage("Successfully uploaded tree", data: ["id": tree.treeId,
                                                                             "md5": tree.imageMd5 ?? ""])
                    completion(.success(true))
                }
            }
        }
    }
    
}
