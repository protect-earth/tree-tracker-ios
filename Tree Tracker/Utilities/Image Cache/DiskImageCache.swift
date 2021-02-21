import Foundation
import class UIKit.UIImage

final class DiskImageCache: Codable, ImageCaching {
    enum Constants {
        static var diskUrl: URL {
            URL.documentsDirectory.appendingPathComponent("imageCache")
        }
    }

    var maxCost: Int

    private var cache: [ImageCacheInfo]
    private lazy var syncQueue = DispatchQueue(label: "com.TreeTracker.syncQueue")

    init(maxCost: Int = 1024 * 1024 * 100, initialCache: [ImageCacheInfo]) {
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
            self?.cache.append(ImageCacheInfo(url: url.absoluteString, imageData: data, imageCost: Int64(data.count)))
            self?.evaluateCostAndPerformActionsIfNecessary()
            self?.saveToDisk()
        }
    }

    private func evaluateCurrentCost() -> Int64 {
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
            self?.cache.removeAll(where: { $0.url == url.absoluteString })
            self?.saveToDisk()
        }
    }

    func image(for url: URL) -> UIImage? {
        return syncQueue.sync {
            cache.first(where: { $0.url == url.absoluteString }).flatMap { UIImage(data: $0.imageData) }
        }
    }
}
