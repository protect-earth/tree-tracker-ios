import Foundation
import Alamofire
import class UIKit.UIImage

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

    func species(offset: String?, completion: @escaping (Result<Paginated<AirtableSpecies>, AFError>) -> Void) {
        let request = session.request(Config.speciesUrl, method: .get, parameters: ["offset": offset].compactMapValues { $0 }, encoding: URLEncoding.queryString, headers: Config.headers, interceptor: nil, requestModifier: nil)

        request.validate().responseDecodable(decoder: JSONDecoder._iso8601ms) { (response: DataResponse<Paginated<AirtableSpecies>, AFError>) in
            completion(response.result)
        }
    }

    func sites(offset: String?, completion: @escaping (Result<Paginated<AirtableSite>, AFError>) -> Void) {
        let request = session.request(Config.sitesUrl, method: .get, parameters: ["offset": offset].compactMapValues { $0 }, encoding: URLEncoding.queryString, headers: Config.headers, interceptor: nil, requestModifier: nil)

        request.validate().responseDecodable(decoder: JSONDecoder._iso8601ms) { (response: DataResponse<Paginated<AirtableSite>, AFError>) in
            completion(response.result)
        }
    }

    func supervisors(offset: String?, completion: @escaping (Result<Paginated<AirtableSupervisor>, AFError>) -> Void) {
        let request = session.request(Config.supervisorsUrl, method: .get, parameters: ["offset": offset].compactMapValues { $0 }, encoding: URLEncoding.queryString, headers: Config.headers, interceptor: nil, requestModifier: nil)

        request.validate().responseDecodable(decoder: JSONDecoder._iso8601ms) { (response: DataResponse<Paginated<AirtableSupervisor>, AFError>) in
            completion(response.result)
        }
    }
    
    func addSite(name: String, completion: @escaping (Result<AirtableSite, AFError>) -> Void) {
        // build struct to represent target JSON body
        let parameters: [String: [String: String]] = [
            "fields": ["Name": name]
        ]
        
        // TODO: does specifying a nil interceptor here override the retrying interceptor we configure at session level?
        let request = session.request(Config.sitesUrl, method: .post, parameters: parameters, encoder: JSONParameterEncoder.default, headers: Config.headers, interceptor: nil, requestModifier: nil)
        
        request.validate().responseDecodable(decoder: JSONDecoder._iso8601ms) { (response: DataResponse<AirtableSite, AFError>) in
            completion(response.result)
        }
    }

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
                    completion(.failure(error))
                }
            }
        }
    }

    private func upload(image: UIImage, session: Session, completion: @escaping (Result<(String, String), AFError>) -> Void) -> Request? {
        logger.log(.api, "Uploading image to Cloudinary...")
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            logger.log(.api, "No pngData for the image, bailing")
            completion(.failure(.explicitlyCancelled))
            return nil
        }

        let md5 = data.md5() ?? ""
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
                self?.logger.log(.api, "Error when uploading image: \(response.data.map { String.init(data: $0, encoding: .utf8) })")
                completion(.failure(error))
            case let .success(json as [String: Any]):
                let url = json["secure_url"] as? String

                if let url = url {
                    completion(.success((url, md5)))
                } else {
                    fallthrough
                }
            default:
                self?.logger.log(.api, "Error when parsing json: \(response.data.map { String.init(data: $0, encoding: .utf8) })")
                completion(.failure(.explicitlyCancelled))
            }
        }
    }

    private func upload(tree: LocalTree, imageUrl: String, session: Session, completion: @escaping (Result<AirtableTree, AFError>) -> Void) -> Request? {
        let airtableTree = tree.toAirtableTree(imageUrl: imageUrl)
        let request = session.request(AlamofireApi.Config.treesUrl, method: .post, parameters: airtableTree, encoder: JSONParameterEncoder(encoder: ._iso8601ms), headers: AlamofireApi.Config.headers, interceptor: nil, requestModifier: nil)

        return request.validate().responseDecodable(decoder: JSONDecoder._iso8601ms) { [weak self] (response: DataResponse<AirtableTree, AFError>) in
            self?.progress?(1.0)

            switch response.result {
            case let .success(tree):
                self?.logger.log(.api, "Tree uploaded!")
                completion(.success(tree))
            case let .failure(error):
                self?.logger.log(.api, "Error when creating Airtable record: \(response.data.map { String.init(data: $0, encoding: .utf8) })")
                completion(.failure(error))
            }
        }
    }
}
