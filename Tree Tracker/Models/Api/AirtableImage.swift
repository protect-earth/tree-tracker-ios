import Foundation

struct AirtableImage: Codable {
    let url: String
    let thumbnailUrl: String?

    enum CodingKeys: String, CodingKey {
        case url
        case thumbnailUrl = "thumbnails"
    }

    init(url: String, thumbnailUrl: String?) {
        self.url = url
        self.thumbnailUrl = thumbnailUrl
    }

    init(from decoder: Decoder) throws {
        var root = try decoder.unkeyedContainer()
        let container = try root.nestedContainer(keyedBy: CodingKeys.self)

        url = try container.decode(String.self, forKey: .url)
        thumbnailUrl = (try? container.decodeIfPresent(AirtableImageThumbnail.self, forKey: .thumbnailUrl))?.url
    }

    func encode(to encoder: Encoder) throws {
        var root = encoder.unkeyedContainer()
        var container = root.nestedContainer(keyedBy: CodingKeys.self)

        try container.encode(url, forKey: .url)
        try container.encodeIfPresent(thumbnailUrl, forKey: .thumbnailUrl)
    }
}
