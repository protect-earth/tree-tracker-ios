import UIKit

protocol ImageCaching {
    func add(image: UIImage, for url: URL)
    func removeImage(for url: URL)
    func image(for url: URL) -> UIImage?
}

final class DiskImageCache: Codable, ImageCaching {
    enum Constants {
        static var diskUrl: URL {
            URL.documentsDirectory.appendingPathComponent("imageCache")
        }
    }

    struct CacheInfo: Codable {
        let url: URL
        let imageData: Data
        let imageCost: Int
    }

    var maxCost: Int

    private var cache: [CacheInfo]
    private lazy var syncQueue = DispatchQueue(label: "com.TreeTracker.syncQueue")

    init(maxCost: Int = 1024 * 1024 * 100, initialCache: [CacheInfo]) {
        self.maxCost = maxCost
        self.cache = initialCache
    }

    static func fromDisk() throws -> DiskImageCache {
        let url = Constants.diskUrl
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(DiskImageCache.self, from: data)
    }

    func saveToDisk() {
        DispatchQueue.global(qos: .utility).async {
            let data = try? JSONEncoder().encode(self)
            try? data?.write(to: Constants.diskUrl)
        }
    }

    func add(image: UIImage, for url: URL) {
        syncQueue.async(flags: .barrier) { [weak self] in
            let data = image.jpegData(compressionQuality: 1.0) ?? Data()
            self?.cache.append(CacheInfo(url: url, imageData: data, imageCost: data.count))
            self?.evaluateCostAndPerformActionsIfNecessary()
            self?.saveToDisk()
        }
    }

    private func evaluateCurrentCost() -> Int {
        cache.reduce(0) { accumulator, element in
            return accumulator + element.imageCost
        }
    }

    private func evaluateCostAndPerformActionsIfNecessary() {
        while (evaluateCurrentCost() > maxCost && cache.isNotEmpty) {
            cache.removeFirst()
        }
    }

    func removeImage(for url: URL) {
        syncQueue.async(flags: .barrier) { [weak self] in
            self?.cache.removeAll(where: { $0.url == url })
            self?.saveToDisk()
        }
    }

    func image(for url: URL) -> UIImage? {
        return syncQueue.sync {
            cache.first(where: { $0.url == url }).flatMap { UIImage(data: $0.imageData) }
        }
    }
}

final class URLImageLoader: ImageLoader {
    let url: String

    var id: String {
        return url
    }

    private let api: Api
    private let thumbnailsImageCache: ImageCaching

    init(url: String, api: Api = CurrentEnvironment.api, thumbnailsImageCache: ImageCaching = CurrentEnvironment.imageCache) {
        self.url = url
        self.api = api
        self.thumbnailsImageCache = thumbnailsImageCache
    }

    func loadThumbnail(completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, let url = URL(string: self.url) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            if let image = self.thumbnailsImageCache.image(for: url) {
                DispatchQueue.main.async {
                    print("Image from cache for url: \(url)")
                    completion(image)
                }

                return
            }

            self.api.loadImage(url: self.url) { [weak self] image in
                guard let self = self, let image = image else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }

                print("Image from the webz for url: \(self.url)")
                self.thumbnailsImageCache.add(image: image, for: url)
                self.resize(image: image, completion: completion)
            }
        }
    }

    private func resize(image: UIImage, completion: @escaping (UIImage?) -> Void) {
        let aspectRatio = image.size.width / image.size.height
        let newSize = CGSize(width: self.thumbnailSize.width, height: self.thumbnailSize.width / aspectRatio)
        let resizedImage = image.resize(to: newSize)
        DispatchQueue.main.async {
            completion(resizedImage)
        }
    }

    func loadHighQualityImage(completion: @escaping (UIImage?) -> Void) {
        api.loadImage(url: url) { image in
            completion(image)
        }
    }

    static func == (lhs: URLImageLoader, rhs: URLImageLoader) -> Bool {
        return lhs.url == rhs.url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}
