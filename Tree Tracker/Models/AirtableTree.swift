import Foundation

struct AirtableTree: Decodable {
    let id: Int
    let supervisor: String
    let species: String
    let notes: String?
    let coordinates: String?
    let what3words: String?
    let imageMd5: String?
    let createDate: Date?
    let uploadDate: Date?
    var imageUrl: String?
    var thumbnailUrl: String?

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case supervisor = "Supervisor"
        case species = "Species"
        case notes = "Notes"
        case coordinates = "Coordinates"
        case what3words = "What3Words"
        case image = "Image"
        case imageMd5 = "ImageSignature"
        case createDate = "CreatedDate"
        case uploadDate = "UploadedDate"
        case fields
    }

    init(id: Int, supervisor: String, species: String, notes: String?, coordinates: String?, what3words: String?, imageUrl: String?, thumbnailUrl: String?, imageMd5: String?, uploadDate: Date?, createDate: Date?) {
        self.id = id
        self.supervisor = supervisor
        self.species = species
        self.notes = notes
        self.coordinates = coordinates
        self.what3words = what3words
        self.imageUrl = imageUrl
        self.thumbnailUrl = thumbnailUrl
        self.imageMd5 = imageMd5
        self.uploadDate = uploadDate
        self.createDate = createDate
    }

    init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: CodingKeys.self)
        let container = try root.nestedContainer(keyedBy: CodingKeys.self, forKey: .fields)

        id = try container.decode(Int.self, forKey: .id)
        supervisor = try container.decode(String.self, forKey: .supervisor)
        species = try container.decode(String.self, forKey: .species)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        coordinates = try container.decodeIfPresent(String.self, forKey: .coordinates)
        what3words = try container.decodeIfPresent(String.self, forKey: .what3words)
        imageMd5 = try container.decodeIfPresent(String.self, forKey: .imageMd5)
        uploadDate = try container.decodeIfPresent(Date.self, forKey: .uploadDate)
        createDate = try container.decodeIfPresent(Date.self, forKey: .createDate)

        do {
            let image = try container.decodeIfPresent(AirtableImage.self, forKey: .image)
            imageUrl = image?.url
            thumbnailUrl = image?.thumbnailUrl
        } catch {
            print("Error decoding airtable image: \(error)")
            imageUrl = nil
            thumbnailUrl = nil
        }
    }

    func toRemoteTree() -> RemoteTree {
        return RemoteTree(id: id, supervisor: supervisor, species: species, notes: notes, coordinates: coordinates, what3words: what3words, imageUrl: imageUrl, thumbnailUrl: thumbnailUrl, imageMd5: imageMd5, createDate: createDate, uploadDate: uploadDate)
    }
}

private struct AirtableImage: Codable {
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

struct AirtableTreeEncodable: Encodable {
    let supervisor: String
    let species: String
    let notes: String?
    let coordinates: String?
    let what3words: String?
    let imageMd5: String?
    let createDate: Date?
    let uploadDate: Date?
    var imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case supervisor = "Supervisor"
        case species = "Species"
        case notes = "Notes"
        case coordinates = "Coordinates"
        case what3words = "What3Words"
        case image = "Image"
        case imageMd5 = "ImageSignature"
        case createDate = "CreatedDate"
        case uploadDate = "UploadedDate"
        case fields
    }

    init(supervisor: String, species: String, notes: String?, coordinates: String?, what3words: String?, imageUrl: String?, imageMd5: String?, uploadDate: Date?, createDate: Date?) {
        self.supervisor = supervisor
        self.species = species
        self.notes = notes
        self.coordinates = coordinates
        self.what3words = what3words
        self.imageUrl = imageUrl
        self.imageMd5 = imageMd5
        self.uploadDate = uploadDate
        self.createDate = createDate
    }

    func encode(to encoder: Encoder) throws {
        var root = encoder.container(keyedBy: CodingKeys.self)
        var container = root.nestedContainer(keyedBy: CodingKeys.self, forKey: .fields)

        try container.encode(supervisor, forKey: .supervisor)
        try container.encode(species, forKey: .species)
        try container.encode(notes, forKey: .notes)
        try container.encode(coordinates, forKey: .coordinates)
        try container.encode(what3words, forKey: .what3words)
        try container.encode(imageMd5, forKey: .imageMd5)
        try container.encode(imageUrl.map { AirtableImage(url: $0, thumbnailUrl: nil) }, forKey: .image)
        try container.encode(uploadDate, forKey: .uploadDate)
        try container.encode(createDate, forKey: .createDate)
    }
}
