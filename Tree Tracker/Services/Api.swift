import Foundation
import Alamofire
import class UIKit.UIImage

struct Paginated<Model: Decodable>: Decodable {
    let offset: String?
    let records: [Model]
}

final class Api {
    private struct Config {
        static let baseUrl = URL(string: "https://api.airtable.com/v0/\(Constants.Airtable.baseId)")!
        static let treesUrl = baseUrl.appendingPathComponent(Constants.Airtable.treesTable)
        static let headers = HTTPHeaders(["Authorization": "Bearer \(Constants.Airtable.apiKey)"])

        enum Cloudinary {
            static let uploadUrl = URL(string: "https://api.cloudinary.com/v1_1/\(Constants.Cloudinary.cloudName)/image/upload")!
        }
    }

    private let session = Session()
    private var imageLoaders = [String: PHImageLoader]()

    func treesPlanted(offset: String? = nil, completion: @escaping (Result<Paginated<AirtableTree>, AFError>) -> Void) {
        let request = session.request(Config.treesUrl, method: .get, parameters: ["offset": offset].compactMapValues { $0 }, encoding: URLEncoding.queryString, headers: Config.headers, interceptor: nil, requestModifier: nil)

        request.validate().responseDecodable(decoder: JSONDecoder._iso8601ms) { (response: DataResponse<Paginated<AirtableTree>, AFError>) in
            completion(response.result)
        }
    }

    func upload(tree: LocalTree, completion: @escaping (Result<AirtableTree, AFError>) -> Void) {
        let imageLoader = PHImageLoader(phImageId: tree.phImageId)
        imageLoaders[tree.phImageId] = imageLoader

        imageLoader.loadHighQualityImage { [weak self] image in
            self?.imageLoaders[tree.phImageId] = nil

            guard let image = image else {
                completion(.failure(AFError.explicitlyCancelled))
                return
            }

            self?.upload(image: image) { result in
                switch result {
                case let .success((url, md5)):
                    var newTree = tree
                    newTree.imageMd5 = md5
                    self?.upload(tree: newTree, imageUrl: url, completion: completion)
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        }
    }

    private func upload(image: UIImage, completion: @escaping (Result<(String, String), AFError>) -> Void) {
        print("Uploading image to Cloudinary...")
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("No pngData for the image, bailing")
            completion(.failure(.explicitlyCancelled))
            return
        }

        let md5 = data.md5() ?? ""
        let request = session.upload(
            multipartFormData: { formData in
                formData.append(data, withName: "file", fileName: "image.jpg", mimeType: "image/jpg")
                formData.append(Constants.Cloudinary.uploadPresetName.data(using: .utf8)!, withName: "upload_preset")
            },
            to: Config.Cloudinary.uploadUrl,
            method: .post)

        request.validate().responseJSON { response in
            switch response.result {
            case let .failure(error):
                print("Error when uploading image: \(response.data.map { String.init(data: $0, encoding: .utf8) })")
                completion(.failure(error))
            case let .success(json as [String: Any]):
                let url = json["secure_url"] as? String

                if let url = url {
                    completion(.success((url, md5)))
                } else {
                    fallthrough
                }
            default:
                print("Error when parsing json: \(response.data.map { String.init(data: $0, encoding: .utf8) })")
                completion(.failure(.explicitlyCancelled))
            }
        }
    }

    private func upload(tree: LocalTree, imageUrl: String, completion: @escaping (Result<AirtableTree, AFError>) -> Void) {
        let airtableTree = tree.toAirtableTree(imageUrl: imageUrl)
        let request = session.request(Config.treesUrl, method: .post, parameters: airtableTree, encoder: JSONParameterEncoder(encoder: ._iso8601ms), headers: Config.headers, interceptor: nil, requestModifier: nil)


        request.validate().responseDecodable(decoder: JSONDecoder._iso8601ms) { (response: DataResponse<AirtableTree, AFError>) in
            switch response.result {
            case let .success(tree):
                print("Tree uploaded!")
                completion(.success(tree))
            case let .failure(error):
                print("Error when creating Airtable record: \(response.data.map { String.init(data: $0, encoding: .utf8) })")
                completion(.failure(error))
            }
        }
    }

    func loadImage(url: String, completion: @escaping (UIImage?) -> Void) {
        let request = session.request(url, method: .get, headers: Config.headers)

        request.validate().responseData { data in
            completion(data.data.flatMap(UIImage.init(data:)))
        }
    }
}
