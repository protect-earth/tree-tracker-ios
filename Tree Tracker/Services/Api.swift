import Foundation
import Alamofire
import class UIKit.UIImage

struct Paginated<Model: Decodable>: Decodable {
    let offset: String?
    let records: [Model]
}

final class Api {
    private struct Config {
        static let baseUrl = URL(string: "https://api.airtable.com/v0/\(Constants.airtableBaseId)")!
        static let treesUrl = baseUrl.appendingPathComponent(Constants.airtableTreesTable)
        static let headers = HTTPHeaders(["Authorization": "Bearer \(Constants.airtableApiKey)"])

        enum Imgur {
            static let uploadUrl = URL(string: "https://api.imgur.com/3/upload")!
            static let headers = HTTPHeaders(["Authorization": "Client-ID \(Constants.imgurClientId)"])
        }
    }

    private let session = Session()
    private var imageLoaders = [String: PHImageLoader]()

    func treesPlanted(offset: String? = nil, completion: @escaping (Result<Paginated<AirtableTree>, AFError>) -> Void) {
        let request = session.request(Config.treesUrl, method: .get, parameters: ["offset": offset].compactMapValues { $0 }, encoding: URLEncoding.queryString, headers: Config.headers, interceptor: nil, requestModifier: nil)

        request.responseDecodable { (response: DataResponse<Paginated<AirtableTree>, AFError>) in
            completion(response.result)
        }
    }

    func upload(tree: Tree, completion: @escaping (Result<AirtableTree, AFError>) -> Void) {
        guard let phImageId = tree.phImageId else {
            completion(.failure(AFError.explicitlyCancelled))
            return
        }

        let imageLoader = PHImageLoader(phImageId: phImageId)
        imageLoaders[phImageId] = imageLoader

        imageLoader.loadHighQualityImage { [weak self] image in
            self?.imageLoaders[phImageId] = nil

            guard let image = image else {
                completion(.failure(AFError.explicitlyCancelled))
                return
            }

            self?.upload(image: image) { result in
                switch result {
                case let .success(url):
                    self?.upload(tree: tree, imageUrl: url, completion: completion)
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        }
    }

    private func upload(image: UIImage, completion: @escaping (Result<String, AFError>) -> Void) {
        guard let data = image.pngData() else {
            completion(.failure(.explicitlyCancelled))
            return
        }

        let request = session.upload(
            multipartFormData: { formData in
                formData.append(data, withName: "image")
            },
            to: Config.Imgur.uploadUrl,
            method: .post,
            headers: Config.Imgur.headers)

        request.responseJSON { response in
            switch response.result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(json as [String: Any]):
                let data = json["data"] as? [String: Any]
                let url = data?["link"] as? String

                if let url = url {
                    completion(.success(url))
                } else {
                    fallthrough
                }
            default:
                completion(.failure(.explicitlyCancelled))
            }
        }
    }

    private func upload(tree: Tree, imageUrl: String, completion: @escaping (Result<AirtableTree, AFError>) -> Void) {
        var airtableTree = tree.toAirtableTree()
        airtableTree.imageUrl = imageUrl

        let request = session.request(Config.treesUrl, method: .post, parameters: airtableTree, encoder: JSONParameterEncoder.default, headers: Config.headers, interceptor: nil, requestModifier: nil)

        request.responseDecodable { (response: DataResponse<Paginated<AirtableTree>, AFError>) in
            switch response.result {
            case let .success(paginatedTrees):
                guard let tree = paginatedTrees.records.first else {
                    completion(.failure(.explicitlyCancelled))
                    return
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
