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
            static let uploadUrl = URL(string: "https://api.imgur.com/3/image")!
            static let headers = HTTPHeaders(["Authorization": "Client-ID \(Constants.imgurClientId)"])
        }
    }

    private let session = Session()
    private var imageLoaders = [String: PHImageLoader]()

    func treesPlanted(offset: String? = nil, completion: @escaping (Result<Paginated<AirtableTree>, AFError>) -> Void) {
        let request = session.request(Config.treesUrl, method: .get, parameters: ["offset": offset].compactMapValues { $0 }, encoding: URLEncoding.queryString, headers: Config.headers, interceptor: nil, requestModifier: nil)

        request.validate().responseDecodable { (response: DataResponse<Paginated<AirtableTree>, AFError>) in
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

            self?.authorizeImgur {
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
    }


    private func authorizeImgur(completion: @escaping () -> Void) {
        let request = session.request("https://api.imgur.com/oauth2/authorize", method: .post, parameters: ["response_type": "token", "client_id": Constants.imgurClientId], encoding: JSONEncoding.default, headers: Config.Imgur.headers)

        request.validate().responseJSON { result in
            switch result.result {
            case let .success(json):
                print("IMGur authorize: success. \(json)")
            case let .failure(error):
                print("IMGur authorize failure. \(result.data.map { String.init(data: $0, encoding: .utf8) })")
            }
            completion()
        }
    }

    private func upload(image: UIImage, completion: @escaping (Result<String, AFError>) -> Void) {
        print("Uploading image to imgur...")
        guard let data = image.pngData() else {
            print("No pngData for the image, bailing")
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

        request.validate().responseJSON { response in
            switch response.result {
            case let .failure(error):
                print("Error when uploading image: \(response.data.map { String.init(data: $0, encoding: .utf8) })")
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
                print("Error when parsing json: \(response.data.map { String.init(data: $0, encoding: .utf8) })")
                completion(.failure(.explicitlyCancelled))
            }
        }
    }

    private func upload(tree: LocalTree, imageUrl: String, completion: @escaping (Result<AirtableTree, AFError>) -> Void) {
        let airtableTree = tree.toAirtableTree(imageUrl: imageUrl)

        let request = session.request(Config.treesUrl, method: .post, parameters: airtableTree, encoder: JSONParameterEncoder.default, headers: Config.headers, interceptor: nil, requestModifier: nil)

        request.validate().responseDecodable { (response: DataResponse<Paginated<AirtableTree>, AFError>) in
            switch response.result {
            case let .success(paginatedTrees):
                guard let tree = paginatedTrees.records.first else {
                    print("Error when fetching Airtable success record: \(response.data.map { String.init(data: $0, encoding: .utf8) })")
                    completion(.failure(.explicitlyCancelled))
                    return
                }
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
