import Foundation

struct AirtableImageThumbnail: Codable {
    let url: String

    enum CodingKeys: String, CodingKey {
        case small
        case large
        case url
    }

    init(url: String) {
        self.url = url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let small = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .large)

        url = try small.decode(String.self, forKey: .url)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var small = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .large)

        try small.encode(url, forKey: .url)
    }
}
