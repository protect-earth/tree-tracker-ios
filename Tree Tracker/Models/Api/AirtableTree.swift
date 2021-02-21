import Foundation

struct AirtableTree: Decodable {
    let id: Int
    let supervisor: String
    let species: String
    let site: String
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
        case site = "Sites"
        case notes = "Notes"
        case coordinates = "Coordinates"
        case what3words = "What3Words"
        case image = "Image"
        case imageMd5 = "ImageSignature"
        case createDate = "CreatedDate"
        case uploadDate = "UploadedDate"
        case fields
    }

    init(id: Int, supervisor: String, species: String, site: String, notes: String?, coordinates: String?, what3words: String?, imageUrl: String?, thumbnailUrl: String?, imageMd5: String?, uploadDate: Date?, createDate: Date?) {
        self.id = id
        self.supervisor = supervisor
        self.species = species
        self.site = site
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
        site = try container.decodeSingleStringInArray(forKey: .site)
        supervisor = try container.decodeSingleStringInArray(forKey: .supervisor)
        species = try container.decodeSingleStringInArray(forKey: .species)
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
            CurrentEnvironment.logger.log("Error decoding airtable image: \(error)")
            imageUrl = nil
            thumbnailUrl = nil
        }
    }

    func toRemoteTree() -> RemoteTree {
        return RemoteTree(id: id, supervisor: supervisor, species: species, site: site, notes: notes, coordinates: coordinates, what3words: what3words, imageUrl: imageUrl, thumbnailUrl: thumbnailUrl, imageMd5: imageMd5, createDate: createDate, uploadDate: uploadDate)
    }
}

struct AirtableTreeEncodable: Encodable {
    let supervisor: String
    let species: String
    let site: String
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
        case site = "Sites"
        case notes = "Notes"
        case coordinates = "Coordinates"
        case what3words = "What3Words"
        case image = "Image"
        case imageMd5 = "ImageSignature"
        case createDate = "CreatedDate"
        case uploadDate = "UploadedDate"
        case fields
    }

    init(supervisor: String, species: String, site: String, notes: String?, coordinates: String?, what3words: String?, imageUrl: String?, imageMd5: String?, uploadDate: Date?, createDate: Date?) {
        self.supervisor = supervisor
        self.species = species
        self.site = site
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

        try container.encodeSingleStringInArray(species, forKey: .species)
        try container.encodeSingleStringInArray(supervisor, forKey: .supervisor)
        try container.encodeSingleStringInArray(site, forKey: .site)
        try container.encode(notes, forKey: .notes)
        try container.encode(coordinates, forKey: .coordinates)
        try container.encode(what3words, forKey: .what3words)
        try container.encode(imageMd5, forKey: .imageMd5)
        try container.encode(imageUrl.map { AirtableImage(url: $0, thumbnailUrl: nil) }, forKey: .image)
        try container.encode(uploadDate, forKey: .uploadDate)
        try container.encode(createDate, forKey: .createDate)
    }
}
