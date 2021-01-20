import Foundation

struct AirtableTree: Decodable {
    let id: Int
    let supervisor: String
    let species: String
    let notes: String?
    let coordinates: String?
    let imageMd5: String?
    let createDate: Date?
    let uploadDate: Date?
    var imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case supervisor = "Supervisor"
        case species = "Species"
        case notes = "Notes"
        case coordinates = "Coordinates"
        case image = "Image"
        case imageMd5 = "ImageSignature"
        case createDate = "CreatedDate"
        case uploadDate = "UploadedDate"
        case fields
    }

    init(id: Int, supervisor: String, species: String, notes: String?, coordinates: String?, imageUrl: String?, imageMd5: String?, uploadDate: Date?, createDate: Date?) {
        self.id = id
        self.supervisor = supervisor
        self.species = species
        self.notes = notes
        self.coordinates = coordinates
        self.imageUrl = imageUrl
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
        imageMd5 = try container.decodeIfPresent(String.self, forKey: .imageMd5)
        uploadDate = try container.decodeIfPresent(Date.self, forKey: .uploadDate)
        createDate = try container.decodeIfPresent(Date.self, forKey: .createDate)

        do {
            let image = try container.decodeIfPresent(AirtableImage.self, forKey: .image)
            imageUrl = image?.url
        } catch {
            print("Error decoding airtable image: \(error)")
            imageUrl = nil
        }
    }

    func toRemoteTree() -> RemoteTree {
        return RemoteTree(id: id, supervisor: supervisor, species: species, notes: notes, coordinates: coordinates, imageUrl: imageUrl, imageMd5: imageMd5, createDate: createDate, uploadDate: uploadDate)
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

    func encode(to encoder: Encoder) throws {
        var root = encoder.unkeyedContainer()
        var container = root.nestedContainer(keyedBy: CodingKeys.self)

        try container.encode(url, forKey: .url)
    }
}

struct AirtableTreeEncodable: Encodable {
    let supervisor: String
    let species: String
    let notes: String?
    let coordinates: String?
    let imageMd5: String?
    let createDate: Date?
    let uploadDate: Date?
    var imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case supervisor = "Supervisor"
        case species = "Species"
        case notes = "Notes"
        case coordinates = "Coordinates"
        case image = "Image"
        case imageMd5 = "ImageSignature"
        case createDate = "CreatedDate"
        case uploadDate = "UploadedDate"
        case fields
    }

    init(supervisor: String, species: String, notes: String?, coordinates: String?, imageUrl: String?, imageMd5: String?, uploadDate: Date?, createDate: Date?) {
        self.supervisor = supervisor
        self.species = species
        self.notes = notes
        self.coordinates = coordinates
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
        try container.encode(imageMd5, forKey: .imageMd5)
        try container.encode(imageUrl.map(AirtableImage.init), forKey: .image)
        try container.encode(uploadDate, forKey: .uploadDate)
        try container.encode(createDate, forKey: .createDate)
    }
}
