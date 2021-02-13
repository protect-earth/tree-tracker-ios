import Foundation
import class Photos.PHCachingImageManager

struct Environment {
    let api: Api
    let database: Database
    let defaults: Defaults
    let imageCache: ImageCaching
    let photosCachingManager: PHCachingImageManager
}

let CurrentEnvironment = Environment(
    api: Api(),
    database: Database(),
    defaults: Defaults(),
    imageCache: (try? DiskImageCache.fromDisk()) ?? DiskImageCache(initialCache: []),
    photosCachingManager: PHCachingImageManager()
)
