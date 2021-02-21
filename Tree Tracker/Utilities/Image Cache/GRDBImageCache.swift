import Foundation
import GRDB
import class UIKit.UIImage

fileprivate extension LogCategory {
    static var cache = LogCategory(name: "GRDBCache")
}

final class GRDBImageCache: ImageCaching {
    private enum Constants {
        static let databaseUrl = URL.documentsDirectory.appendingPathComponent("imagecache.sqlite")
    }

    var maxCost: Int
    
    private let dbQueue: DatabaseQueue?
    private let logger: Logging
    
    init(maxCost: Int = 1024 * 1024 * 500, databasePath: String = Constants.databaseUrl.path, logger: Logging = CurrentEnvironment.logger) {
        self.maxCost = maxCost
        self.dbQueue = try? DatabaseQueue(path: databasePath)
        self.logger = logger

        do {
            try createTablesIfNeeded()
        } catch {
            logger.log(.cache, "Error when creating a table for image cache info. \(error)")
        }
    }

    private func createTablesIfNeeded() throws {
        try dbQueue?.write { db in
            if try db.tableExists(ImageCacheInfo.databaseTableName) == false {
                try db.create(table: ImageCacheInfo.databaseTableName) { table in
                    table.column(ImageCacheInfo.CodingKeys.url.stringValue, .text)
                    table.column(ImageCacheInfo.CodingKeys.imageCost.stringValue, .text)
                    table.column(ImageCacheInfo.CodingKeys.imageData.stringValue, .blob)

                    table.autoIncrementedPrimaryKey("id")
                    table.uniqueKey([ImageCacheInfo.CodingKeys.url.stringValue])
                }
            }
        }
    }

    func add(image: UIImage, for url: URL) {
        logger.log(.cache, "Adding image to cache (\(url))")
        dbQueue?.asyncWriteWithoutTransaction { [weak self] db in
            guard let self = self else { return }
            
            let data = image.jpegData(compressionQuality: 1.0) ?? Data()
            let info = ImageCacheInfo(url: url.absoluteString, imageData: data, imageCost: Int64(data.count))
            self.logger.log(.cache, "Image cost: \(info.imageCost) (\(url))")
            let cacheCostQuery = ImageCacheInfo.select(sum(Column(ImageCacheInfo.CodingKeys.imageCost.rawValue)))
            do {
                var cacheCost = try Int64.fetchOne(db, cacheCostQuery) ?? 0
                self.logger.log(.cache, "Current cache cost: \(cacheCost). Max cost: \(self.maxCost)")
                while (cacheCost + info.imageCost) > self.maxCost && cacheCost > 0 && self.maxCost > 0 {
                    self.logger.log(.cache, "Current cost bigger than max, removing the oldest image...")
                    do {
                        try ImageCacheInfo.order(Column("id").asc).limit(1).deleteAll(db)
                        cacheCost = (try? Int64.fetchOne(db, cacheCostQuery)) ?? 0
                        self.logger.log(.cache, "Removed the oldest image, current cache cost: \(cacheCost)")
                    } catch {
                        self.logger.log(.cache, "Couldn't remove an image: \(error)")
                        break
                    }
                }
                
                try? info.insert(db)
                self.logger.log(.cache, "Added image to cache (\(url))")
            } catch {
                self.logger.log(.cache, "Error when fetching current cache cost: \(error)")
            }
        }
    }

    func removeImage(for url: URL) {
        logger.log(.cache, "Removing image for url (\(url))")
        dbQueue?.asyncWriteWithoutTransaction { [weak self] db in
            do {
                try ImageCacheInfo.filter(Column(ImageCacheInfo.CodingKeys.url) == url.absoluteString)
                    .deleteAll(db)
                self?.logger.log(.cache, "Image removed! \(url)")
            } catch {
                self?.logger.log(.cache, "Couldn't remove an image: \(error)")
            }
        }
    }

    func image(for url: URL) -> UIImage? {
        logger.log(.cache, "Retrieving image for url (\(url)")
        return dbQueue?.barrierWriteWithoutTransaction { [weak self] db -> UIImage? in
            do {
                let image = try ImageCacheInfo.filter(Column(ImageCacheInfo.CodingKeys.url) == url.absoluteString)
                    .fetchOne(db)
                self?.logger.log(.cache, "Image for url retrieved! \(url)")
                return image.flatMap { UIImage(data: $0.imageData) }
            } catch {
                self?.logger.log(.cache, "Couldn't retrieve an image for url \(url)")
                return nil
            }
        }
    }
}
