import Foundation
import Resolver
import Alamofire
import UIKit
import RollbarNotifier

class ProtectEarthTreeService: TreeService {

    @Injected private var database: Database
    @Injected private var sessionFactory: AlamofireSessionFactory
    @Injected private var cloudinarySessionFactory: CloudinarySessionFactory
    
    let cloudinaryUploadUrl = URL(string: "https://api.cloudinary.com/v1_1/\(Constants.Cloudinary.cloudName)/image/upload")!
    
    func publish(tree: LocalTree, progress: @escaping (Double) -> Void, completion: @escaping (Result<Bool, DataAccessError>) -> Void) {
        // Step 1: retrieve image at appropriate resolution
        prepareImageForUpload(tree: tree) { [weak self] (image: UIImage?) in
            
            guard let self = self else { return }
            
            guard let image = image else {
                return completion(.failure(DataAccessError.localError(errorCode: 1,
                                                               errorMessage: "Unable to prepare upload image")))
            }
            
            progress(0.1)
            
            // Step 2: upload image to cloudinary
            self.uploadImageToImageStore(image: image, progress: progress) { imageUploadResult in

                switch imageUploadResult {
                case let .success((url, md5)):
                    var newTree = tree
                    newTree.imageMd5 = md5

                    // Step 3: post tree details to API and remove tree from queue
                    self.postMetadata(tree: newTree, imageStoreUrl: url, completion: completion)

                case let .failure(error):
                    Rollbar.errorError(error,
                                       data: ["md5": tree.imageMd5 ?? "",
                                              "phImageId": tree.phImageId,
                                              "coordinates": tree.coordinates ?? "",
                                              "supervisor": tree.supervisor,
                                              "site": tree.site],
                                       context: "Fetching upload image for tree")
                    completion(.failure(DataAccessError.remoteError(errorCode: error.responseCode ?? -1,
                                                                    errorMessage: error.errorDescription ?? "")))
                }
            }
        }
    }
    
    func prepareImageForUpload(tree: LocalTree, completion: @escaping (UIImage?) -> Void) {
        let imageLoader = PHImageLoader(phImageId: tree.phImageId)
        imageLoader.loadUploadImage(completion: completion)
    }
    
    func uploadImageToImageStore(image: UIImage,
                                 progress: @escaping (Double) -> Void,
                                 completion: @escaping (Result<(String, String), AFError>) -> Void) {
        let cloudinarySession = cloudinarySessionFactory.get()
        
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            Rollbar.errorMessage("No pngData for image, upload will be skipped")
            completion(.failure(.explicitlyCancelled))
            return
        }
        
        let md5 = data.md5()
        let request = cloudinarySession
            .upload(
                multipartFormData: { formData in
                    formData.append(data, withName: "file", fileName: "image.jpg", mimeType: "image/jpg")
                    formData.append(Constants.Cloudinary.uploadPresetName.data(using: .utf8)!, withName: "upload_preset")
                },
                to: cloudinaryUploadUrl,
                method: .post
            )
            .uploadProgress { uploadProgress in
                // as we expect uploading of the image to be our most network intensive
                // phase of the upload process we allow this operation to consume the
                // 10-90% complete segment of our total progress
                progress(0.1 + 0.8 * uploadProgress.fractionCompleted)
            }
        
        request
            .validate(statusCode: [200])
            .cURLDescription { desc in
                print(desc)
            }
            .responseDecodable(of: CloudinaryUploadResponse.self) { response in
                switch response.result {
                case let .failure(error):
                    Rollbar.errorError(error,
                                       data: [:],
                                       context: response.dataAsUTF8String())
                    completion(.failure(error))
                case let.success(response):
                    guard let url = response.secureUrl else { fallthrough }
                    completion(.success((url, md5)))
                default:
                    Rollbar.errorMessage("Error while parsing JSON",
                                         data: [:],
                                         context: response.dataAsUTF8String())
                    completion(.failure(.explicitlyCancelled))
                }
            }
    }
    
    func postMetadata(tree: LocalTree, imageStoreUrl: String, completion: @escaping (Result<Bool, DataAccessError>) -> Void) {
        
        guard let plantedDate = tree.createDate else { return }
        guard let coordinates: [String] = tree.coordinates?.components(separatedBy: ", ") else { return }
        guard let latitude = Decimal(string: coordinates[0]) else { return }
        guard let longitude = Decimal(string: coordinates[1]) else { return }
        //guard let md5 = tree.imageMd5 else { return }
        
        let treeMeta = ProtectEarthUpload(imageUrl: imageStoreUrl,
                                          latitude: latitude,
                                          longitude: longitude,
                                          plantedAt: plantedDate,
                                          supervisor: ProtectEarthIdentifier(id: tree.supervisor),
                                          site: ProtectEarthIdentifier(id: tree.site),
                                          species: ProtectEarthIdentifier(id: tree.species))
        
        let encoder = JSONEncoder()
        // php api doesn't like escaped slashes
        encoder.outputFormatting = .init(arrayLiteral: [.sortedKeys, .withoutEscapingSlashes])
        encoder.dateEncodingStrategy = .iso8601
        
        //TODO: use a genuine persisted identity value different from the photo id
        let headers : HTTPHeaders = ["Idempotency-Key": UUID().uuidString]
        let request = getSession().request(sessionFactory.getTreeUrl(),
                                           method: .post,
                                           parameters: treeMeta,
                                           encoder: JSONParameterEncoder(encoder: encoder),
                                           headers: headers)
        
        request
            .cURLDescription { description in
                print(description)
            }
            .validate(statusCode: [201])
            .response { response in
                switch response.result {
                case .success:
                    self.database.remove(tree: tree) {
                        Rollbar.infoMessage("Successfully uploaded tree", data: ["id": "TODO",
                                                                                 "md5": tree.imageMd5 ?? ""])
                        completion(.success(true))
                    }
                case let .failure(error):
                    completion(.failure(DataAccessError.remoteError(errorCode: error.responseCode ?? -1,
                                                                    errorMessage: error.errorDescription ?? "No description")))
                }
            }
    }
    
    private func getSession() -> Session {
        sessionFactory.get()
    }
    
}
