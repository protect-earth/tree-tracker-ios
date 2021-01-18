import Foundation

struct AirtableTree: Codable {
    let id: Int?
    let supervisor: String
    let species: String
    let notes: String?
    let imageMd5: String?
    let uploadDate: Date?
    var imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case supervisor = "Supervisor"
        case species = "Species"
        case notes = "Notes"
        case image = "Image"
        case imageMd5 = "ImageMD5"
        case uploadDate = "UploadDate"
        case fields
    }

    init(id: Int?, supervisor: String, species: String, notes: String?, imageUrl: String?, imageMd5: String?, uploadDate: Date?) {
        self.id = id
        self.supervisor = supervisor
        self.species = species
        self.notes = notes
        self.imageUrl = imageUrl
        self.imageMd5 = imageMd5
        self.uploadDate = uploadDate
    }

    init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: CodingKeys.self)
        let container = try root.nestedContainer(keyedBy: CodingKeys.self, forKey: .fields)

        id = try container.decode(Int.self, forKey: .id)
        supervisor = try container.decode(String.self, forKey: .supervisor)
        species = try container.decode(String.self, forKey: .species)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        imageMd5 = try container.decodeIfPresent(String.self, forKey: .imageMd5)
        uploadDate = try container.decodeIfPresent(Date.self, forKey: .uploadDate)

        do {
            let image = try container.decodeIfPresent(AirtableImage.self, forKey: .image)
            imageUrl = image?.url
        } catch {
            print("error decoding airtable image: \(error)")
            imageUrl = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var root = encoder.container(keyedBy: CodingKeys.self)
        var container = root.nestedContainer(keyedBy: CodingKeys.self, forKey: .fields)

        try container.encode(id, forKey: .id)
        try container.encode(supervisor, forKey: .supervisor)
        try container.encode(species, forKey: .species)
        try container.encode(notes, forKey: .notes)
        try container.encode(imageUrl.map(AirtableImage.init), forKey: .id)
    }

    func toTree() -> Tree {
        return Tree(supervisor: supervisor, species: species, notes: notes, imageMd5: imageMd5, phImageId: nil, remoteId: id, uploadDate: uploadDate)
    }
}

private struct AirtableImage: Codable {
    let url: String

    enum CodingKeys: String, CodingKey {
        case url
    }

    init(url: String) {
        self.url = url
    }

    init(from decoder: Decoder) throws {
        var root = try decoder.unkeyedContainer()
        let container = try root.nestedContainer(keyedBy: CodingKeys.self)

        url = try container.decode(String.self, forKey: .url)
    }
}
