import Foundation
import Alamofire
import class UIKit.UIImage
import RollbarNotifier

fileprivate extension LogCategory {
    static var api = LogCategory(name: "Api")
}

final class AlamofireApi: Api {
    fileprivate struct Config {
        static let baseUrl = URL(string: "https://api.airtable.com/v0/\(Constants.Airtable.baseId)")!
        static let treesUrl = baseUrl.appendingPathComponent(Constants.Airtable.treesTable)
        static let supervisorsUrl = baseUrl.appendingPathComponent(Constants.Airtable.supervisorsTable)
        static let sitesUrl = baseUrl.appendingPathComponent(Constants.Airtable.sitesTable)
        static let speciesUrl = baseUrl.appendingPathComponent(Constants.Airtable.speciesTable)
        static let headers = HTTPHeaders(["Authorization": "Bearer \(Constants.Airtable.apiKey)"])

        enum Cloudinary {
            static let uploadUrl = URL(string: "https://api.cloudinary.com/v1_1/\(Constants.Cloudinary.cloudName)/image/upload")!
        }
    }

    private let session: Session
    private let logger: Logging
    private var imageLoaders = [String: PHImageLoader]()

    init(logger: Logging = CurrentEnvironment.logger) {
        self.logger = logger
        
        let sessionConfig = URLSessionConfiguration.af.default
        sessionConfig.timeoutIntervalForRequest = Constants.Http.requestTimeoutSeconds
        sessionConfig.waitsForConnectivity = Constants.Http.requestWaitsForConnectivity
        
        self.session = Session(configuration: sessionConfig,
                               interceptor: RetryingRequestInterceptor(retryDelaySecs: Constants.Http.requestRetryDelaySeconds,
                                                                       maxRetries: Constants.Http.requestRetryLimit))
        
    }

    @available(*, deprecated, message: "Replaced by ProtectEarthTreeService")
    func upload(tree: LocalTree, progress: @escaping (Double) -> Void = { _ in }, completion: @escaping (Result<AirtableTree, AFError>) -> Void) -> Cancellable {
        let upload = ImageUpload(tree: tree, logger: logger)
        upload.upload(tree: tree, progress: progress, session: session, completion: completion)

        return upload
    }

    func loadImage(url: String, completion: @escaping (UIImage?) -> Void) {
        let request = session.request(url, method: .get, headers: Config.headers)

        request.validate().responseData { data in
            completion(data.data.flatMap(UIImage.init(data:)))
        }
    }
}

@available(*, deprecated, message: "Replaced by ProtectEarthTreeService")
final class ImageUpload: Cancellable {
    private let tree: LocalTree
    private let imageLoader: PHImageLoader
    private let logger: Logging

    private var request: Request?
    private var progress: ((Double) -> Void)?
    private var isCancelled = false

    init(tree: LocalTree, logger: Logging = CurrentEnvironment.logger) {
        self.tree = tree
        self.imageLoader = PHImageLoader(phImageId: tree.phImageId)
        self.logger = logger
    }

    func cancel() {
        guard !isCancelled else { return }

        isCancelled = true
        request?.cancel()
    }

    func upload(tree: LocalTree, progress: @escaping (Double) -> Void = { _ in }, session: Session, completion: @escaping (Result<AirtableTree, AFError>) -> Void) {
        self.progress = progress

        // issue-48 - upload images at 1150x1530px size
        imageLoader.loadUploadImage { [weak self] image in
            guard self?.isCancelled != true else {
                completion(.failure(AFError.explicitlyCancelled))
                return
            }

            guard let image = image else {
                completion(.failure(AFError.explicitlyCancelled))
                return
            }

            self?.progress?(0.2)

            self?.request = self?.upload(image: image, session: session) { result in
                switch result {
                case let .success((url, md5)):
                    var newTree = tree
                    newTree.imageMd5 = md5
                    self?.request = self?.upload(tree: newTree, imageUrl: url, session: session, completion: completion)
                case let .failure(error):
                    Rollbar.errorError(error,
                                       data: ["md5": tree.imageMd5 ?? "",
                                              "phImageId": tree.phImageId,
                                              "coordinates": tree.coordinates ?? "",
                                              "supervisor": tree.supervisor,
                                              "site": tree.site],
                                       context: "Fetching upload image for tree")
                    completion(.failure(error))
                }
            }
        }
    }

    private func upload(image: UIImage, session: Session, completion: @escaping (Result<(String, String), AFError>) -> Void) -> Request? {
        logger.log(.api, "Uploading image to Cloudinary...")
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            logger.log(.api, "No pngData for the image, bailing")
            Rollbar.errorMessage("No pngData for image, upload will be skipped")
            completion(.failure(.explicitlyCancelled))
            return nil
        }

        let md5 = data.md5()
        let request = session
            .upload(
                multipartFormData: { formData in
                    formData.append(data, withName: "file", fileName: "image.jpg", mimeType: "image/jpg")
                    formData.append(Constants.Cloudinary.uploadPresetName.data(using: .utf8)!, withName: "upload_preset")
                },
                to: AlamofireApi.Config.Cloudinary.uploadUrl,
                method: .post
            ).uploadProgress { progress in
                self.progress?(0.2 + 0.75 * progress.fractionCompleted)
            }

        return request.validate().responseJSON { [weak self] response in
            switch response.result {
            case let .failure(error):
                Rollbar.errorError(error,
                                   data: [:],
                                   context: response.dataAsUTF8String())
                self?.logger.log(.api, "Error when uploading image: \(response.dataAsUTF8String())")
                completion(.failure(error))
            case let .success(json as [String: Any]):
                let url = json["secure_url"] as? String

                if let url = url {
                    completion(.success((url, md5)))
                } else {
                    fallthrough
                }
            default:
                Rollbar.errorMessage("Error while parsing JSON",
                                     data: [:],
                                     context: response.dataAsUTF8String())
                self?.logger.log(.api, "Error when parsing json: \(response.dataAsUTF8String())")
                completion(.failure(.explicitlyCancelled))
            }
        }
    }

    private func upload(tree: LocalTree, imageUrl: String, session: Session, completion: @escaping (Result<AirtableTree, AFError>) -> Void) -> Request? {
        let airtableTree = tree.toAirtableTree(imageUrl: imageUrl)
        let request = session.request(AlamofireApi.Config.treesUrl, method: .post, parameters: airtableTree, encoder: JSONParameterEncoder(encoder: ._iso8601ms), headers: AlamofireApi.Config.headers)

        return request.validate().responseDecodable(decoder: JSONDecoder._iso8601ms) { [weak self] (response: DataResponse<AirtableTree, AFError>) in
            self?.progress?(1.0)

            switch response.result {
            case let .success(tree):
                self?.logger.log(.api, "Tree uploaded!")
                completion(.success(tree))
            case let .failure(error):
                Rollbar.errorError(error,
                                   data: [:],
                                   context: response.dataAsUTF8String())
                self?.logger.log(.api, "Error when creating Airtable record: \(response.dataAsUTF8String())")
                completion(.failure(error))
            }
        }
    }
}
